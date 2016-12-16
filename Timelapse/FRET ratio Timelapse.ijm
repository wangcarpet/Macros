/*###################################
###      DEFAULT SETTINGS         ###
### Edit according to your needs! ###
###################################*/

ExpName = "Test8";
CFPchannelName = "w1CFPex CFPem FRET";
YFPchannelName = "w2CFPex YFPem FRET";

CellSize_Min = 1700;
CellSize_Max = 3500;

run("Set Measurements...", "area mean integrated display redirect=None decimal=3");

/*###################################
###        END OF SETTINGS        ###
####################################*/

// Ask for user input (config)
Base_Folder = getDirectory("Input");

Dialog.create("Config");
Dialog.addString("Exp. name:", ExpName);
Dialog.addString("CFP Channel name:", CFPchannelName);
Dialog.addString("YFP Channel name:", YFPchannelName);
Dialog.addNumber("Start with pos.", 1);
Dialog.addNumber("End with pos.", 10);
Dialog.addNumber("Start with time:", 1);
Dialog.addNumber("End with time:", 10);
Dialog.addChoice("Threshold:", newArray("Huang", "Li", "Triangle", "Default", "Intermodes", "IsoData", "IJ_IsoData", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Yen"));
Dialog.addNumber("Min. Cell size:", CellSize_Min);
Dialog.addNumber("Max. Cell size:", CellSize_Max);
Dialog.addCheckbox("Manual segmentation (no auto threshold)", false);
Dialog.show();
ExpName = Dialog.getString();
CFPchannelName = Dialog.getString();
YFPchannelName = Dialog.getString();
startPosNumber = Dialog.getNumber();
endPosNumber = Dialog.getNumber();
startTime = Dialog.getNumber();
endTime = Dialog.getNumber();
thresholdType = Dialog.getChoice();
CellSize_Min = Dialog.getNumber();
CellSize_Max = Dialog.getNumber();
ManualMode = Dialog.getCheckbox();


// Script begins here
ResultTable_CurrentPos=0;

for (CurrentPosition=startPosNumber; CurrentPosition<=endPosNumber; CurrentPosition++){
    for (CurrentTime=startTime; CurrentTime<=endTime; CurrentTime++){

        pathYFP = Base_Folder + CurrentPosition + "/" + YFPchannelName + "/" + ExpName + "_" + YFPchannelName + "_s" + CurrentPosition + "_t" + CurrentTime + ".TIF";
        pathCFP = Base_Folder + CurrentPosition + "/" + CFPchannelName + "/" + ExpName + "_" + CFPchannelName + "_s" + CurrentPosition + "_t" + CurrentTime + ".TIF";

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
            //roiManager("Rename", "Pos" + CurrentPosition + "_t" + CurrentTime + "_Cell" + CellNumber);
            roiManager("Rename", "Pos" + CurrentPosition + "_Cell" + CellNumber + "_t" + CurrentTime);
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
            roiManager("Rename", "Pos" + CurrentPosition + "_t" + CurrentTime + "_BG" );

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
            print("Pos" + CurrentPosition + "_t" + CurrentTime + ": problem with segmentation.");
        }

        ROInumber = roiManager("count");
        if(ROInumber != 0){
            roiManager("Deselect");
            roiManager("Delete");
        }
    }
}




