/*###############################################
##   Settings: edit according to your needs!   ##
####_________________________________________##*/
run("Set Measurements...", "area mean integrated display redirect=None decimal=3");
CellPropertyArray = newArray("Late telophase", "Early G1", "Other");
AskCellProperty = true;


/*#####################################
##   Create a ROI for each nucleus   ##
####_______________________________##*/
run("Threshold...");
roiManager("Show All with labels");
waitForUser("Segment cells into ROIs, then press OK.");
CellNumber = roiManager("count");

for (i=0; i<CellNumber; i++){
    // Rename
    CurrentCell=i+1;
    roiManager("Select", i);
    roiManager("Rename", "Cell_" + CurrentCell);

    // Measure
    roiManager("Select", i);
    run("Measure");

    if (AskCellProperty==true){
        // Ask about cell properties
        roiManager("Show None");
        Dialog.create("Cell " + CurrentCell);
        Dialog.addChoice("Cell property:", CellPropertyArray);
        Dialog.show();
        CellProperty = Dialog.getChoice();
        setResult("Type", i, CellProperty);
    }
}

/*########################################
##   Create a single ROI for all foci   ##
####__________________________________##*/
run("Threshold...");
waitForUser("Turn foci into ROIs, then press OK.");
LastFociROI = roiManager("count") - 1;
FociNumber_Total = LastFociROI - CellNumber + 1;

// Create array including all foci ROI
Foci_Array = newArray(FociNumber_Total)
j=0;
for (i=CellNumber; i<=LastFociROI; i++){
    Foci_Array[j] = i;
    j=j+1;
}

// Fuse all foci ROI into one single ROI
roiManager("Select", Foci_Array);
roiManager("Combine");
roiManager("Add");
roiManager("Select", Foci_Array);
roiManager("Delete");
roiManager("Select", CellNumber);
roiManager("Rename", "Foci_All");


/*#################################################
##   Create individual foci ROIs for each cell   ##
####___________________________________________##*/
FociROI_All = roiManager("count") - 1;

setBatchMode(true);

// Split FociROI_All into each cells
for (i=0; i<CellNumber;  i++){
    roiManager("Select", newArray(i,FociROI_All));
    roiManager("AND");
    roiManager("Add");
    CurrentCell=i+1;
    // TODO: Bug => if empty cell, then crashes here
    FociROI_CurrentCell = CellNumber + 1 + i;
    roiManager("Select", FociROI_CurrentCell);
    roiManager("Rename", "Cell" + CurrentCell + "_AllFoci");
}

// Split each FociROI_Cell_n into individual ROIs with appropriate names
FociROI_FirstCell = FociROI_All + 1;
FociROI_LastCell = roiManager("count") - 1;
CurrentCell = 1;
k = 0;

for (i=FociROI_FirstCell; i<=FociROI_LastCell; i++){
    FociIndROI_CurrentCell_First = roiManager("count");
    roiManager("Select", i);
    run("Create Mask");
    run("Analyze Particles...", "size=0-300 pixel show=[Overlay Masks] include add in_situ");
    FociIndROI_CurrentCell_Last = roiManager("count") - 1;

    // Add number of foci per cell in result table
    CurrentCell_ROW = CurrentCell - 1;
    FociPerCells_CurrentCell = FociIndROI_CurrentCell_Last - FociIndROI_CurrentCell_First + 1;
    setResult("Foci per cell", CurrentCell_ROW, FociPerCells_CurrentCell);
    setResult("Cell number", CurrentCell_ROW, CurrentCell);

    // Loop to rename individual foci
    FociNumber_CurrentCell = 1;
    for (j=FociIndROI_CurrentCell_First; j<=FociIndROI_CurrentCell_Last; j++){
        roiManager("Select", j);
        roiManager("Rename", "Cell_" + CurrentCell + "_Foci_" + FociNumber_CurrentCell);

        // Add individual ROIs to result table
        CurrentFoci_ROW = CellNumber + k;
        roiManager("Select", j);
        run("Measure");
        setResult("Cell number", CurrentFoci_ROW, CurrentCell);

        if (AskCellProperty==true){
            CellProperty_Foci = getResult("Area", CurrentCell_ROW);
            setResult("Type", CurrentFoci_ROW, CellProperty_Foci);
        }

        k = k + 1;
        FociNumber_CurrentCell = FociNumber_CurrentCell + 1;
    }

    CurrentCell = CurrentCell + 1;
}
