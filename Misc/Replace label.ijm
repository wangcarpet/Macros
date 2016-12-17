macro "Rename Labels in Results Table" {
  for (i=0; i<nResults; i++) {
    oldLabel = getResultLabel(i);
    delimiter = indexOf(oldLabel, ":");
    newLabel = substring(oldLabel, delimiter+1);
	print(newLabel);
    setResult("Label", i, newLabel);
    setResult("ID", i, newLabel);

//oldLabel = getResultLabel(0);
//splitLabelel = split(oldLabel,":");
//print(spellitLabel[0]);
//print(spellitLabel[1]);
//print(spellitLabel[2]);

  }
}
