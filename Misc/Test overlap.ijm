//Test overlap between ROI 0 and all the others
ROInumber = roiManager("count");
for (i=1 ; i <ROInumber ; i++){
	ROIarray = newArray(0,i);
	roiManager("Select", ROIarray);
	roiManager("AND");
	if (selectionType() != -1){
		CurrentROI = i+1;
		print(CurrentROI + " : ROIs overlap!");
	}
}
