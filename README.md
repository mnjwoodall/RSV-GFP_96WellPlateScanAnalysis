# GFP Signal Analysis Macro for Vero Cells

## Overview
This macro is designed to analyze GFP fluorescence intensity in Vero cells infected with RSV-GFP using images acquired from a Nikon Inverted Fluorescence Microscope at 4x magnification with full well scans. The macro processes `.nd2` image files, focusing on the FITC channel (GFP) and ignoring transmitted light. It assumes that the well is 100% confluent and helps estimate the viral titre based on control wells.

## Requirements
- **Microscopy**: 
  - Images should be acquired at 4x magnification with both transmitted light and GFP channels split.
  - `.nd2` files are compatible.
- **Control Wells**: 
  - A **virus-only control well** with a known viral titre for calibration.
  - An **uninfected control well** (0 titre) to establish a baseline.

## Analysis Process
- The macro measures the percentage of GFP-positive coverage in each well.
- It compares the % coverage from the experimental wells to the control wells to estimate the viral titre.

## Viral Titre Estimation Equation
The viral titre can be estimated using the following formula:

**Estimated Titre (PFU/ml) = (% Coverage / % Coverage of Control Well) × Known Titre of Control Well**

Where:
- **% Coverage**: The GFP-positive area measured by the macro in your experimental well.
- **% Coverage of Control Well**: The GFP-positive area measured in the virus-only control well.
- **Known Titre of Control Well**: The viral titre value known from the control well.

Where:
- **% Coverage**: The GFP-positive area measured by the macro in your experimental well.
- **% Coverage of Control Well**: The GFP-positive area measured in the virus-only control well.
- **Known Titre of Control Well**: The viral titre value known from the control well.

## Important Considerations
- **High Autofluorescence/Background**: 
  - High background fluorescence can interfere with the macro's accuracy.
  - Minimize autofluorescence by using consistent media or switching to PBS for imaging, as phenol red present in some media can increase background fluorescence.
- **Media Consistency**: 
  - Ensure that the media used between plates is consistent to prevent variability in fluorescence measurements.
  - 
### Note for High Autofluorescence Analysis
If your images exhibit high autofluorescence, particularly if taken with interfering light (e.g., without the dark cover on the microscope stage), use the "High Autofluorescence Macro" instead - this includes an extra step to adjust the threshold if necessary manually. The standard macro should be sufficient and more time efficient for images with normal autofluorescence.

## Output
The macro generates:
- **Binary masks** highlighting the GFP-positive regions.
- A **summary file** with the calculated percentage coverage and particle analysis for each well.

## How to Use the Macro
1. **Install ImageJ** if you haven't already.
2. Open the macro script (`TransductionEfficiencyMacro.ijm`) in ImageJ.
3. Follow the prompts to analyze your `.nd2` files in a chosen directory.

## License
This project is licensed under the [Apache License 2.0](./LICENSE) - see the LICENSE file for details.

## Author
- **Max Woodall** - Creator and maintainer of the macro script.

