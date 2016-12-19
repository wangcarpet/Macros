/*   INSTRUCTIONS:
1) Add ROIs for each cells at each timepoints
2) Add ROI for BG noise
3) Run this script to measure everything and calculate FRET ratio

For the script to work properly the filesystem structure should be:
BaseFolder > Position > ChannelFolder > Timepoints.TIF
And you should open the folder "ChannelFolder" as a stack

*/

//######  Settings #######
CFPchannelName = "w1CFPex CFPem FRET";
YFPchannelName = "w2CFPex YFPem FRET";
run("Set Measurements...", "area mean integrated stack display redirect=None decimal=3");
//########################

waitForUser("Do you have ROI for each cell at each timepoints, and a ROI for BGnoise?");

//Get some info
YFPpath = getInfo("image.directory")
delimiter = indexOf(YFPpath, YFPchannelName);
BasePath = substring(YFPpath, 0, delimiter);
CFPpath = BasePath + CFPchannelName;

splitPath = split(BasePath,"/");
Array.reverse(splitPath);
CurrentPosition = splitPath[0];
CurrentCondition = splitPath[1];

//Measure everything
setBatchMode(true);
CellNumber = roiManager("count") - 1;
BG_ROI = CellNumber;
roiManager("Select", BG_ROI);
roiManager("Rename", "BG Roi");

//YFP channel
YFP_FirstRow = getValue("results.count");
open(YFPpath)
for (CurrentROI=0; CurrentROI<CellNumber; CurrentROI++){
    roiManager("Select", CurrentROI);
    run("Measure");
}
// BG in YFP channel
YFP_BG_FirstRow=getValue("results.count");
for (Slice=1; Slice<=nSlices; Slice++){
    roiManager("Select", BG_ROI);
    setSlice(Slice);
    roiManager("Measure");
}
close();

//CFP channel
CFP_FirstRow = getValue("results.count");
open(CFPpath)
for (CurrentROI=0; CurrentROI<CellNumber; CurrentROI++){
    roiManager("Select", CurrentROI);
    run("Measure");
}
CFP_BG_FirstRow=getValue("results.count");
for (Slice=1; Slice<=nSlices; Slice++){
    roiManager("Select", BG_ROI);
    setSlice(Slice);
    roiManager("Measure");
}
close();

//Manipulate result table
YFP_BG_Slice = newArray(nSlices);
CFP_BG_Slice = newArray(nSlices);

i=0;
for (YFP_BG_Row=YFP_BG_FirstRow; YFP_BG_Row<CFP_FirstRow; YFP_BG_Row++){
    YFP_BG_Slice[i] = getResult("Mean", YFP_BG_Row);
    CFP_BG_Row = CFP_BG_FirstRow + i;
    CFP_BG_Slice[i] = getResult("Mean", CFP_BG_Row);
    i++;
}

for (i=0; i<CellNumber; i++) {
    YFP_CurrentRow = YFP_FirstRow + i;
    CFP_CurrentRow = CFP_FirstRow + i;

    //Calculate integrated density adjusted to BG noise
    Area_CurrentRow = getResult("Area", YFP_CurrentRow);
    roiManager("Select", i);
    CurrentSlice = getSliceNumber() - 1;

    YFP_IntDens_CurrentRow = getResult("IntDen", YFP_CurrentRow);
    YFP_BGnoise_CurrentRow = Area_CurrentRow * YFP_BG_Slice[CurrentSlice];
    YFP_Adjusted_CurrentRow = YFP_IntDens_CurrentRow - YFP_BGnoise_CurrentRow;
    CFP_IntDens_CurrentRow = getResult("IntDen", CFP_CurrentRow);
    CFP_BGnoise_CurrentRow = Area_CurrentRow * CFP_BG_Slice[CurrentSlice];
    CFP_Adjusted_CurrentRow = CFP_IntDens_CurrentRow - CFP_BGnoise_CurrentRow;

    //FRET ratio
    YFPonCFP_CurrentRow = YFP_Adjusted_CurrentRow / CFP_Adjusted_CurrentRow;
    CFPonYFP_CurrentRow = CFP_Adjusted_CurrentRow / YFP_Adjusted_CurrentRow;

    //Add results to table
    setResult("BG Noise", CFP_CurrentRow, CFP_BGnoise_CurrentRow);
    setResult("BG Noise", YFP_CurrentRow, YFP_BGnoise_CurrentRow);
    setResult("Adjusted IntDen", CFP_CurrentRow, CFP_Adjusted_CurrentRow);
    setResult("Adjusted IntDen", YFP_CurrentRow, YFP_Adjusted_CurrentRow);
    setResult("YFPonCFP", YFP_CurrentRow, YFPonCFP_CurrentRow);
    setResult("CFPonYFP", YFP_CurrentRow, CFPonYFP_CurrentRow);

    //To help sort the data table
    setResult("Exp. Position", YFP_CurrentRow, CurrentPosition);
    setResult("Exp. Condition", YFP_CurrentRow, CurrentCondition);
    
}

setBatchMode(false);
