/* Calculate Number of foci per ROI
    1) Add your ROIs (eg: for each nuclei, or in a zone)
    2) Run script: it asks you for a threshold to get all foci
    3) That's it!
*/

/*########################################
##                Settings              ##
####__________________________________##*/

run("Set Measurements...", "area mean integrated display redirect=None decimal=3");



/*########################################
##   Create a single ROI for all foci   ##
####__________________________________##*/
CellNumber = roiManager("count");

// Measure whatever there is to measure in the cells
for (i=0; i<CellNumber; i++) {
    roiManager("Select", i);
    run("Measure");
}

//Ask user to threshold foci
run("Threshold...");
waitForUser("Turn foci into ROIs, then press OK.");
LastFociROI = roiManager("count") - 1;
FociNumber_Total = LastFociROI - CellNumber + 1;

// Create array including all foci ROI
Foci_Array = newArray(FociNumber_Total)
j=0;
for (i=CellNumber; i<=LastFociROI; i++){
    Foci_Array[j] = i;
    j++;
}

// Fuse all foci ROI into one *single* ROI and rename it to "Foci_All"
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
FociROI_All = CellNumber;

setBatchMode(true);

ROI_Array = newArray(CellNumber);

// Split FociROI_All into each ROI and rename it
j=0;
for (i=0; i<CellNumber;  i++){
    roiManager("Select", newArray(i,FociROI_All));
    roiManager("AND");
    if (selectionType()==-1){
        ROI_Array[i]=-1;
    } else {
        roiManager("Add");
        FociROI_CurrentCell = CellNumber + 1 + j;
        CurrentROI_Name = call("ij.plugin.frame.RoiManager.getName", i);
        roiManager("Select", FociROI_CurrentCell);
        roiManager("Rename", CurrentROI_Name + "_AllFoci");
        ROI_Array[i]=FociROI_CurrentCell;
        j++;
    }
}

// Split each FociROI_Cell_n into individual ROIs with appropriate names
CurrentROI = 0;
k = 0;

for (i=0; i<CellNumber; i++){
    CurrentROI_Name = call("ij.plugin.frame.RoiManager.getName", i);
    if (ROI_Array[i] != -1) {
        FociIndROI_CurrentROI_First = roiManager("count");
        roiManager("Select", ROI_Array[i]);
        run("Create Mask");
        run("Analyze Particles...", "size=0-300 pixel show=[Overlay Masks] include add in_situ");
        FociIndROI_CurrentROI_Last = roiManager("count") - 1;

        // Add number of foci per ROI in result table
        FociPerROI_CurrentROI = FociIndROI_CurrentROI_Last - FociIndROI_CurrentROI_First + 1;
        setResult("Foci per ROI", i, FociPerROI_CurrentROI);
        setResult("ROI overlap", i, CurrentROI_Name);

        // Loop to rename individual foci
        FociNumber_CurrentCell = 1;
        for (j=FociIndROI_CurrentROI_First; j<=FociIndROI_CurrentROI_Last; j++){
            roiManager("Select", j);
            roiManager("Rename", CurrentROI_Name + "_Foci_" + FociNumber_CurrentCell);

            // Add individual ROIs to result table
            //CurrentFoci_ROW = CellNumber + k;
            //roiManager("Select", j);
            //run("Measure");
            //setResult("ROI overlap", CurrentFoci_ROW, CurrentROI_Name);
            //k = k + 1;

            FociNumber_CurrentCell = FociNumber_CurrentCell + 1;
        }

        CurrentCell = CurrentCell + 1;
    } else {
        setResult("Foci per ROI", i, 0);
        setResult("ROI overlap", i, CurrentROI_Name);
    }
}
