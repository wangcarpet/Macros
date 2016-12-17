/*   INSTRUCTIONS:
1) Add ROIs for each cells at each timepoints
2) Add ROI for BG noise
3) Run this script to measure everything and calculate FRET ratio

For the script to work properly the filesystem structure should be:
BaseFolder > Position > ChannelFolder > Timepoints.TIF
And you should open the folder "ChannelFolder" as a stack

*/

//######  Settings #######
ExpName = "Test8";
CFPchannelName = "w1CFPex CFPem FRET";
YFPchannelName = "w2CFPex YFPem FRET";
run("Set Measurements...", "area mean integrated stack display redirect=None decimal=3");
//########################

waitForUser("Do you have ROI for each cell at each timepoints, and a ROI for BGnoise ?");

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
ROInumber = roiManager("count");
YFP_FirstRow = getValue("results.count");
YFP_BG_Row = YFP_FirstRow + ROInumber - 1;
CFP_FirstRow = YFP_FirstRow + ROInumber;
CFP_BG_Row = CFP_FirstRow + ROInumber - 1;

//YFP channel
open(YFPpath)
for (CurrentROI=0; CurrentROI<ROInumber; CurrentROI++){
    roiManager("Select", CurrentROI);
    run("Measure");
}
close();

//CFP channel
open(CFPpath)
for (CurrentROI=0; CurrentROI<ROInumber; CurrentROI++){
    roiManager("Select", CurrentROI);
    run("Measure");
}
close();

//Manipulate result table
Mean_BG_YFP = getResult("Mean", YFP_BG_Row);
Mean_BG_CFP = getResult("Mean", CFP_BG_Row);

for (i=0; i<(ROInumber - 1); i++) {
    YFP_CurrentRow = YFP_FirstRow + i;
    CFP_CurrentRow = CFP_FirstRow + i;

    //Calculate integrated density adjusted to BG noise
    Area_CurrentRow = getResult("Area", YFP_CurrentRow);

    YFP_IntDens_CurrentRow = getResult("IntDen", YFP_CurrentRow);
    YFP_BGnoise_CurrentRow = Area_CurrentRow * Mean_BG_YFP;
    YFP_Adjusted_CurrentRow = YFP_IntDens_CurrentRow - YFP_BGnoise_CurrentRow;
    CFP_IntDens_CurrentRow = getResult("IntDen", CFP_CurrentRow);
    CFP_BGnoise_CurrentRow = Area_CurrentRow * Mean_BG_CFP;
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
}

setBatchMode(false);
