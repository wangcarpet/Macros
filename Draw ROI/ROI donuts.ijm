// Settings
Dilate_Out = 30;
Dilate_In = 10;

//Dialog.create("Config");
//Dialog.addNumber("Dilate (inner):", Dilate_In);
//Dialog.addNumber("Dilate (outer):", Dilate_Out);
//Dialog.show();
//Dilate_In = Dialog.getNumber();
//Dilate_Out = Dialog.getNumber();

// Get ROI
//waitForUser("This will take all your ROIs and create a donut around them.");
ROInumber = roiManager("count");
//for (i=0; i<ROInumber; i++) {
//    ROINumber = ROINumber + 1;
//    roiManager("Select", i);
//    roiManager("Rename", "Cell" + ROINumber + "_Nucleus");
//}

OriginalImageID = getImageID();
setBatchMode(true);

DonutArray = newArray(ROInumber)
// Make donut for current cell
for (i=0; i<ROInumber; i++){
    roiManager("Select", i);
    CurrentROI_Name = call("ij.plugin.frame.RoiManager.getName", i);
    run("Create Mask");
    for (j = 0; j<= Dilate_Out; j++){
        run("Dilate");
    }
    run("Analyze Particles...", "exclude include add");
    OuterRim_CurrentROI = roiManager("count") - 1;

    roiManager("Select", i);
    run("Create Mask");
    for (j = 0; j<= Dilate_In; j++){
        run("Dilate");
    }
    run("Analyze Particles...", "exclude include add");
    InnerRim_CurrentROI = OuterRim_CurrentROI + 1;

    DonutRims_CurrentROI = newArray(InnerRim_CurrentROI, OuterRim_CurrentROI);

    roiManager("Select", DonutRims_CurrentROI);
    roiManager("XOR");
    roiManager("Add");

    roiManager("Select", DonutRims_CurrentROI);
    roiManager("Delete");
    Donut_CurrentROI = roiManager("count") - 1;

    roiManager("Select", Donut_CurrentROI);
    roiManager("Rename", CurrentROI_Name + "_Donut");
    DonutArray[i]= roiManager("index");
}

//Set correct position for ROI donut in stack
selectImage(OriginalImageID);
setBatchMode(false);

for (i=0; i<ROInumber; i++){
    roiManager("Select", i);
    CurrentROI_Slice=getSliceNumber();
    roiManager("Deselect");
    roiManager("Select", DonutArray[i]);
    setSlice(CurrentROI_Slice);
    roiManager("Add");
}
roiManager("Deselect");
roiManager("Select", DonutArray);
roiManager("Delete")
