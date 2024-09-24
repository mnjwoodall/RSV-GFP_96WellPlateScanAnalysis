/*  
 *  RSV-GFP Analysis Macro for High Autofluorescence Conditions in Vero Cells
 * 
 *  This macro processes a batch of microscopy images to quantify the GFP signal while accounting for high autofluorescence.
 *  When the mean fluorescence intensity (MFI) is above 1000, it will apply extra steps to eliminate the bright autofluorescence
 *  at the edges of the well, focusing the analysis on the central region only.
 * 
 *  Copyright (c) 2024 Max Woodall 
 */// Last updated 2024-09-24 // 12:27 PM 

// Prompt the user to select the input directory containing the images
inputDir = getDirectory("Select the directory containing the images to process");

// Define the output directory relative to the input directory
outputDir = inputDir + "High_Autofluorescence_Results" + File.separator;

// Create the output directory if it doesn't exist
File.makeDirectory(outputDir);

// Get a list of all files and directories in the input directory
fileList = getFileList(inputDir);

// Loop through each item in the list
for (i = 0; i < fileList.length; i++) {

    // Get the current file name
    fileName = fileList[i];

    // Skip the item if it's a directory or not an image file
    if (File.isDirectory(inputDir + fileName) || startsWith(fileName, "Intensity") || endsWith(fileName, ".xls")) {
        continue;
    }

    // Open the image using Bio-Formats Importer with autoscale and split channels enabled
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

    /////////////////////////High Autofluorescence Adjustment Starts Here//////////////////////////

    // Duplicate the selected channel image to avoid modifying the original data
    run("Duplicate...", " ");
    
    // Declare the variable to store mean intensity
    meanIntensity = 0;

    // Calculate the Mean Fluorescence Intensity (MFI) of the image
    getStatistics(meanIntensity);

    // Check if the MFI is above 1000, indicating high autofluorescence
    if (meanIntensity > 1000) {
        
        // Inform the user that the macro is adjusting for high autofluorescence
        print("High autofluorescence detected (MFI = " + meanIntensity + "). Adjusting...");

        // Make an oval in the center of the image to exclude the outer bright edges
        makeOval(700, 1000, 3850, 3850);
        
        // Create a mask from the oval and clear the outside to retain only the central area
        run("Clear Outside");
        
        // Subtract background with a rolling ball radius of 50 to reduce background noise
        run("Subtract Background...", "rolling=50");

        // Convert to 8-bit grayscale for thresholding
        run("8-bit");

        // Allow the user to check the thresholding and confirm if GFP signals are being captured correctly
        setAutoThreshold("Triangle dark no-reset"); // Initial threshold suggestion
        waitForUser("Check the threshold. Adjust the settings if necessary to ensure GFP signals are properly captured. Click OK to continue.");
        
        // Convert to mask based on the user’s thresholding adjustments
        run("Convert to Mask");

        // Apply Watershed to separate connected regions
        run("Watershed");

    } else {
        // When autofluorescence is not high (MFI <= 1000), proceed with regular background subtraction
        print("Normal autofluorescence detected (MFI = " + meanIntensity + "). Using standard analysis...");
        run("Subtract Background...", "rolling=50");
        run("8-bit");

        // Apply the Triangle threshold method as default
        setAutoThreshold("Triangle dark no-reset");
        run("Convert to Mask");
        run("Watershed");
    }

    // Analyze particles within the defined area, size excludes small debris (<100 pixels), generate mask and summary
    run("Analyze Particles...", "size=100-Infinity show=Masks display exclude summarize");

    /////////////////////////Analysis Ends Here///////////////////////

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
