macro "Rename Labels in Results Table" {
  for (i=0; i<nResults; i++) {
    oldLabel = getResultLabel(i);
    delimiter = indexOf(oldLabel, ":");
    newLabel = substring(oldLabel, delimiter+1);
	print(newLabel);
    setResult("ID", i, newLabel);
  }
}