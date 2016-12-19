//Calculate FRET ratio in percent
for (Row=0; Row<nResults; Row++){
    Slice = getResult("Slice", Row);
    YFPonCFP = getResult("YFPonCFP", Row);
    CFPonYFP = getResult("CFPonYFP", Row);
    if (Slice==1) {
        YFPonCFP_origin=YFPonCFP;
        CFPonYFP_origin=CFPonYFP;
        YoC_percent=100;
        CoY_percent=100;
    } else {
        YoC_percent=YFPonCFP*100/YFPonCFP_origin;
        CoY_percent=CFPonYFP*100/CFPonYFP_origin;
    }
    setResult("YoC", Row, YoC_percent);
    setResult("CoY", Row, CoY_percent);
}
