// Settings
Dilate_Out = 30;
Dilate_In = 10;

Dialog.create("Config");
Dialog.addNumber("Dilate (inner):", Dilate_In);
Dialog.addNumber("Dilate (outer):", Dilate_Out);
Dialog.show();
Dilate_In = Dialog.getNumber();
Dilate_Out = Dialog.getNumber();

// Get nuclei
waitForUser("Please add ROI for each nuclei.");
ROInumber = roiManager("count");
CellNumber = 0;
for (i=0; i<ROInumber; i++) {
    CellNumber = CellNumber + 1;
    roiManager("Select", i);
    roiManager("Rename", "Cell" + CellNumber + "_Nucleus");
}

setBatchMode(true);
// Make donut for current cell
for (i=0; i<CellNumber; i++){
    CurrentCell = i + 1;
    roiManager("Select", i);
    run("Create Mask");
    for (j = 0; j<= Dilate_Out; j++){
        run("Dilate");
    }
    run("Analyze Particles...", "exclude include add");
    OuterRim_CurrentCell = roiManager("count") - 1;

    roiManager("Select", i);
    run("Create Mask");
    for (j = 0; j<= Dilate_In; j++){
        run("Dilate");
    }
    run("Analyze Particles...", "exclude include add");
    InnerRim_CurrentCell = OuterRim_CurrentCell + 1;

    DonutRims_CurrentCell = newArray(InnerRim_CurrentCell, OuterRim_CurrentCell);

    roiManager("Select", DonutRims_CurrentCell);
    roiManager("XOR");
    roiManager("Add");

    roiManager("Select", DonutRims_CurrentCell);
    roiManager("Delete");
    Donut_CurrentCell = roiManager("count") - 1;

    roiManager("Select", Donut_CurrentCell);
    roiManager("Rename", "Cell" + CurrentCell + "_Donut");
}
