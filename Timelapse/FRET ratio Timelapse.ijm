/*###################################
###      DEFAULT SETTINGS         ###
### Edit according to your needs! ###
###################################*/

imageCFPchannel = "40X with DRUG_w1CFPex CFPem FRET_s";
imageYFPchannel = "40X with DRUG_w2CFPex YFPem FRET_s";

filetype = ".TIF";

CellSize_Min = 1700;
CellSize_Max = 3500;

run("Set Measurements...", "area mean integrated display redirect=None decimal=3");

/*###################################
###        END OF SETTINGS        ###
####################################*/

// Ask for user input (config)
CFP_Folder = getDirectory("Input");
YFP_Folder = getDirectory("Input");

Dialog.create("Config");
Dialog.addString("CFP channel base name:", imageCFPchannel, 30);
Dialog.addString("YFP channel base name:", imageYFPchannel, 30);
Dialog.addNumber("Start with pos.", 1);
Dialog.addNumber("End with pos.", 10);
Dialog.addChoice("Threshold:", newArray("Huang", "Li", "Triangle", "Default", "Intermodes", "IsoData", "IJ_IsoData", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Yen"));
Dialog.addNumber("Min. Cell size:", CellSize_Min);
Dialog.addNumber("Max. Cell size:", CellSize_Max);
Dialog.addCheckbox("Manual segmentation (no auto threshold)", false);
Dialog.show();
imageCFPchannel = Dialog.getString();
imageYFPchannel = Dialog.getString();
startPosNumber = Dialog.getNumber();
endPosNumber = Dialog.getNumber();
thresholdType = Dialog.getChoice();
CellSize_Min = Dialog.getNumber();
CellSize_Max = Dialog.getNumber();
ManualMode = Dialog.getCheckbox();


// Script begins here
ResultTable_CurrentPos=0;

for (fileNumber=startPosNumber; fileNumber<=endPosNumber; fileNumber++){

    pathYFP = YFP_Folder + imageYFPchannel + fileNumber + filetype;
    pathCFP = CFP_Folder + imageCFPchannel + fileNumber + filetype;

    if (ManualMode==false){
        // Use threshold to segment cells
        setBatchMode(true);
        open(pathYFP);
        setAutoThreshold(thresholdType + " dark");
        run("Convert to Mask");

        setBatchMode(false); //if batchmode on, cannot save ROI list

        run("Analyze Particles...", "size=" + CellSize_Min + "-" + CellSize_Max + " exclude include add");
        close();

        // Ask user if happy w/ segmentation
        run("ROI Manager...");
        open(pathYFP);

        run("Fire");
        roiManager("Show All");
        roiManager("Show All with labels");

        Dialog.create("Are you satisfied?");
        Dialog.addCheckbox("CHECK this box if you are satisfied with segmentation.", true);
        Dialog.show();
        NiceSegmentation = Dialog.getCheckbox();
    } else {
        // Manually add ROIs
        setBatchMode(false);
        open(pathYFP);
        run("Fire");
        setTool("wand");
        run("Wand Tool...", "tolerance=0 mode=Legacy");
        waitForUser("Add ROI for each cell.");
        NiceSegmentation = true;
    }

    // Rename ROIs
    ROInumber = roiManager("count");
    CellNumber = 1;
    for (i=0; i<ROInumber; i++) {
        roiManager("Select", i);
        roiManager("Rename", "Pos" + fileNumber + "_Cell" + CellNumber);
        CellNumber = CellNumber + 1;
    }

    if (NiceSegmentation==true){
        /*##################################
        ##   Measure signal in each cell  ##
        ##################################*/
        // Add ROI for BG noise
        run("Brightness/Contrast...");
        setTool("oval");
        waitForUser("Add ROI for BG noise.");
        ROInumber = roiManager("count");
        BG_ROI = ROInumber - 1;
        roiManager("Select", BG_ROI);
        roiManager("Rename", "Pos" + fileNumber + "_BG");

        setBatchMode(true);

        // Measure signal from YFP channel
        for (i=0; i<ROInumber; i++) {
            roiManager("Select", i);
            run("Measure");
        }
        close();

        // Measure signal from CFP channel
        open(pathCFP);
        for (i=0; i<ROInumber; i++) {
            roiManager("Select", i);
            run("Measure");
        }
        close();

        /*#############################
        ##   Calculate FRET ratio    ##
        #############################*/
        // Find where I am in the result table
        BGrow_YFP = ResultTable_CurrentPos + BG_ROI;
        BGrow_CFP = 2*BGrow_YFP-ResultTable_CurrentPos+1;

        for (i=ResultTable_CurrentPos; i<BGrow_YFP; i++) {
            Row_CurrentCell_YFP = i;
            Row_CurrentCell_CFP = Row_CurrentCell_YFP + (BGrow_YFP-ResultTable_CurrentPos+1);

            // Calculate adjusted intensity for YFP channel
            MeanBG_CurrentPos_YFP = getResult("Mean", BGrow_YFP);
            Area_CurrentCell_YFP = getResult("Area", Row_CurrentCell_YFP);
            IntDen_CurrentCell_YFP = getResult("IntDen", Row_CurrentCell_YFP);
            BG_CurrentCell_YFP = MeanBG_CurrentPos_YFP*Area_CurrentCell_YFP;
            AdjustedIntDen_CurrentCell_YFP = IntDen_CurrentCell_YFP-BG_CurrentCell_YFP;

            setResult("BG noise", Row_CurrentCell_YFP, BG_CurrentCell_YFP);
            setResult("AdjustedIntD.", Row_CurrentCell_YFP, AdjustedIntDen_CurrentCell_YFP);

            // Calculate adjusted intensity for CFP channel
            MeanBG_CurrentPos_CFP = getResult("Mean", BGrow_CFP);
            Area_CurrentCell_CFP = getResult("Area", Row_CurrentCell_CFP);
            IntDen_CurrentCell_CFP = getResult("IntDen", Row_CurrentCell_CFP);
            BG_CurrentCell_CFP = MeanBG_CurrentPos_CFP*Area_CurrentCell_CFP;
            AdjustedIntDen_CurrentCell_CFP = IntDen_CurrentCell_CFP-BG_CurrentCell_CFP;

            setResult("BG noise", Row_CurrentCell_CFP, BG_CurrentCell_CFP);
            setResult("AdjustedIntD.", Row_CurrentCell_CFP, AdjustedIntDen_CurrentCell_CFP);

            //Calculate FRET RATIO
            YFPonCFP_CurrentCell = AdjustedIntDen_CurrentCell_YFP/AdjustedIntDen_CurrentCell_CFP;
            CFPonYFP_CurrentCell = AdjustedIntDen_CurrentCell_CFP/AdjustedIntDen_CurrentCell_YFP;

            setResult("YFP/CFP", Row_CurrentCell_YFP, YFPonCFP_CurrentCell);
            setResult("CFP/YFP", Row_CurrentCell_YFP, CFPonYFP_CurrentCell);
        }

        ResultTable_CurrentPos=BGrow_CFP + 1;

    } else {
        close();
        print("Pos" + fileNumber + ": problem with segmentation.");
    }

    ROInumber = roiManager("count");
    if(ROInumber != 0){
        roiManager("Deselect");
        roiManager("Delete");
    }
}




