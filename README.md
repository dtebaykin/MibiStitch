# MibiStitch
Support scripts for generating and stitching tiled runs

Setup and usage:
1) Download (clone) repository
2) Generate tiled XML:
  Use MibiWriteTilingXmlCenterRect.m
    The script generates a tiled XML file from the default MIBI 1 point setup XML (input XML file). Provide desired number of 
      rows, columns and overlap between frames.
    Input: MibiWriteTilingXmlCenterRect('outputFileName.xml','inputFileName.xml',TileSize,NumRows,NumCols,Overlap)
    Example: Example: MibiWriteTilingXmlCenterRect('test.xml','180615-HIGHPRESET.xml',5600,5,6,200)
3) Check the generated XML:
  Use MibiDrawDirection.m (with the newly generated XML file)
4) ------- Perform MIBI run -------
5a) If stitching a single channel: use MibiStitchMosaicSmooth.m (Follow instructions inside the script for settings)
5b) If stitching multiple channels: use MibiStitchAllChannels.m (Follow instructions inside the script for settings)
