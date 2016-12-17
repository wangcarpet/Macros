//###### Settings ########
MinMaxSize="100-1000"
ThresholdMethod="Huang"

//########################

getDimensions(width, height, channels, slices, frames);
LastTime=slices;
CurrentCell=1;

do {
    waitForUser("Add ROI for the cell you want to follow");
    Cell_prevFrame=roiManager("count")-1;
    roiManager("Select", Cell_prevFrame);
    Original_Cell_SLICE = getSliceNumber();
    roiManager("Rename", "Cell" + CurrentCell + "_t" + Original_Cell_SLICE);

    run("Select None");
    run("Duplicate...", "duplicate");
    setAutoThreshold(ThresholdMethod + " dark");
    run("Convert to Mask", "method=" + ThresholdMethod + " background=Dark");

    for (Time=Original_Cell_SLICE + 1; Time <=LastTime ; Time++) {
        Found=0;
        setSlice(Time);
        print(getSliceNumber());
        run("Select None");
        run("Duplicate...", "duplicate");
        run("Analyze Particles...", "size=" + MinMaxSize + " exclude include add in_situ slice");
        print(getSliceNumber());
        CurrentTime_ROInumber = roiManager("count");
        for (i=CurrentTime_ROInumber - 1 ; i > Cell_prevFrame ; i--){
            print("i="+i);
            OverlapTest = newArray(Cell_prevFrame, i);
            roiManager("Select", OverlapTest);
            roiManager("AND");
            if (selectionType() == -1){
                print("Delete "+i);
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
