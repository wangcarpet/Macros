//###### Settings ########
MinMaxSize="500-10000"
ThresholdMethod="Otsu"
CurrentCell=1;

//########################

getDimensions(width, height, channels, slices, frames);
LastTime=slices;

do {
    waitForUser("Add ROI for the cell you want to follow and take time to try different thresholding methods (last used: " + ThresholdMethod + ")");
    Cell_prevFrame=roiManager("count")-1;
    roiManager("Select", Cell_prevFrame);
    Original_Cell_SLICE = getSliceNumber();
    roiManager("Rename", "Cell" + CurrentCell + "_t" + Original_Cell_SLICE);

    Dialog.create("Config");
    Dialog.addChoice("Threshold:", newArray(ThresholdMethod, "Huang", "Li", "Triangle", "Default", "Intermodes", "IsoData", "IJ_IsoData", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Yen"));
    Dialog.show();
    ThresholdMethod = Dialog.getChoice();


    run("Select None");
    run("Duplicate...", "duplicate");
    setAutoThreshold(ThresholdMethod + " dark");
    run("Convert to Mask", "method=" + ThresholdMethod + " background=Dark");

    waitForUser("Any treatment to binary mask? (Watershed...)");

    for (Time=Original_Cell_SLICE + 1; Time <=LastTime ; Time++) {
        Found=0;
        setSlice(Time);
        run("Select None");
        run("Duplicate...", "duplicate");
        run("Analyze Particles...", "size=" + MinMaxSize + " exclude include add in_situ slice");
        CurrentTime_ROInumber = roiManager("count");
        for (i=CurrentTime_ROInumber - 1 ; i > Cell_prevFrame ; i--){
            OverlapTest = newArray(Cell_prevFrame, i);
            roiManager("Select", OverlapTest);
            roiManager("AND");
            if (selectionType() == -1){
                roiManager("Deselect");
                roiManager("Select", i);
                roiManager("Delete");
            } else {
                Found++;
            }
        }
        close();
        if (Found == 0)
            exit("Could not find any overlapping ROI in t" + Time);
        if (Found > 1)
            exit("Found more than one overlapping ROI in t" + Time);

        Cell_prevFrame++;
        roiManager("Select", Cell_prevFrame);
        roiManager("Rename", "Cell" + CurrentCell + "_t" + Time);
    }
    close();
    //Ask user if he wants to continue
    waitForUser("Please review segmentation: are you satisfied?");

    Dialog.create("Do you want to continue?");
    Dialog.addCheckbox("CHECK this box if you want to add a new cell.", false);
    Dialog.show();
    Continue = Dialog.getCheckbox();

    CurrentCell++;
} while (Continue==true)
