/*  
 *  Macro to count RSV-GFP infected Vero Cells in a 96 well plate
 * 
 *  This macro processes a batch of microscopy images to quantify the fluorescence intensity of GFP (FITC channel) in Vero cells infected with RSV-GFP.
 *  
 *  This script counts GFP-positive signals and generates masks for each processed image. It saves the results in a specified output directory.
 * 
 *  Copyright (c) 2024 Max Woodall 
 */  
// Last updated 2024-09-15 // 15:20 PM 

// Prompt the user to select the input directory containing the images
inputDir = getDirectory("Select the directory containing the images to process");

// Define the output directory relative to the input directory
outputDir = inputDir + "Intensity_Results" + File.separator;

// Create the output directory if it doesn't exist
File.makeDirectory(outputDir);

// Get a list of all files in the input directory
fileList = getFileList(inputDir);

// Loop through each file in the directory
for (i = 0; i < fileList.length; i++) {

    // Get the current file name
    fileName = fileList[i];

    // Skip any files that start with "Intensity" or have ".xls" extensions, to avoid reprocessing results or non-image files
    if (startsWith(fileName, "Intensity") || endsWith(fileName, ".xls")) {
        continue;
    }

    // Open the image using Bio-Formats Importer with autoscale and split channels enabled
    // Autoscale ensures image intensity is automatically adjusted, and split_channels separates multi-channel images
    run("Bio-Formats Importer", "open=[" + inputDir + fileName + "] autoscale split_channels view=Hyperstack stack_order=XYCZT");

    // Get a list of all open windows (channels) after splitting
    windowList = getList("image.titles");

    // Check if there is more than one channel and select the GFP channel (C=1) appropriately
    channelFound = false;
    for (j = 0; j < windowList.length; j++) {
        if (endsWith(windowList[j], " - C=1")) { // C=1 typically corresponds to the FITC (GFP) channel
            selectWindow(windowList[j]);
            channelFound = true;
            break;
        }
    }

    // If the FITC (C=1) channel doesn't exist, select C=0 as a fallback
    if (!channelFound) {
        for (j = 0; j < windowList.length; j++) {
            if (endsWith(windowList[j], " - C=0")) {
                selectWindow(windowList[j]);
                break;
            }
        }
    }

    /////////////////////////This is where the analysis starts//////////////////////////

    // Duplicate the selected channel image to avoid modifying the original data
    run("Duplicate...", " ");

    // Subtract background with a rolling ball radius of 50 to reduce background noise, enhancing signal-to-noise ratio
    run("Subtract Background...", "rolling=50");
    
    // Convert the image to 8-bit grayscale, which is suitable for thresholding and mask creation
    run("8-bit");

    // Apply a Gaussian Blur filter (sigma=1) to smooth out noise (currently commented out, optional step)
    //run("Gaussian Blur...", "sigma=1");

    // Automatically set a threshold using the Triangle method optimized for darker objects
    setAutoThreshold("Triangle dark no-reset");

    // Convert the thresholded image to a binary mask where pixel values are either 0 (black) or 255 (white)
    run("Convert to Mask");

    // Apply Watershed to separate connected regions, improving individual cell identification
    run("Watershed");

    // Automatically create an oval of specified size and position it in the center of the image
    // This helps in focusing the analysis on the main area of interest, avoiding image edges
    makeOval(700, 1000, 3850, 3850);

    // Pause the macro to allow the user to adjust the oval position as needed for optimal coverage of cells
    waitForUser("Please move the oval to the appropriate position and click OK to continue.");

    // Analyze particles within the defined area, with size set to exclude small debris (<100 pixels), and generate a mask and summary
    run("Analyze Particles...", "size=100-Infinity show=Masks display exclude summarize");

    //////////////Analysis finishes here////////////////////

    // Save the generated mask image for the current file
    saveAs("Tiff", outputDir + "Mask_" + fileName);

    // Close the current image and any associated windows to free up memory
    close();
    run("Close All");
}

// Save the overall summary data as an Excel-compatible file in the output directory
selectWindow("Summary");
saveAs("Text", outputDir + "Count_Summary.xls");

// Notify the user that the process is complete and display the output directory location
print("Processing complete. Masks and summaries saved in the folder: " + outputDir);
