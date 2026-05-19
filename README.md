<!-- 
-- +==== BEGIN KiCad combiner =================+
-- LOGO:
-- .................................
-- .+-------+..+-------+..+-------+.
-- .|.LIB.A.|..|.LIB.B.|..|.LIB.C.|.
-- .+-------+..+-------+..+-------+.
-- ....|...........|..........|.....
-- ....+-----------+----------+.....
-- ................|................
-- .........+--------------+........
-- .........|.LIB.Combined.|........
-- .........+--------------+........
-- .................................
-- /STOP
-- PROJECT: KiCad combiner
-- FILE: README.md
-- CREATION DATE: 19-05-2026
-- LAST Modified: 15:36:55 19-05-2026
-- DESCRIPTION:
-- This is a program that allows you to combine all the KiCad libraries into a single instance.
-- This would make importing easier, less files to add to the KiCad import list.
-- /STOP
-- COPYRIGHT: (c) Henry Letellier
-- PURPOSE: This is the readme file containing the explanation for the repository, how the scripts work, how to import everything and the updates the repository has seen due to KiCad evolution.
-- // AR
-- +==== END KiCad combiner =================+
-->
# My KiCad Mods

This repository is a collection of custom KiCad libraries, footprints, symbols, and 3D models for electronic design automation (EDA) using KiCad. It aggregates various open-source KiCad libraries and provides a build system to compile them into usable formats.

## Disclaimer

This script and bundle was written for kicad 9, while they work for kicad 10, one single big pretty folder (Misc.pretty) will make kicad crash, it is thus recommended to search for all the .pretty folders and copy them to a folder of your choice, a script for kicad 10 might be written in the future to automate that, but no garante.
I would recommend you treat this repository as a big archive for symbols that can be used in kicad.
I would still recommend you run the script (v1) on your system as it will compile the 3D models into a single folder making import easier.

The script 1.1 has been updated (and is the default bash script (builder.sh) located at the root of the directory) to generate the original single big library, but also put all the individual libraries in a single folder making it easier to import (you won't need to navigate each child repository for their symbols, 3D files, etc)

## Repository Structure

- **`builder.sh`**: A shell script that builds the libraries from the source directories into the `build/` folder.
- **`build/`**: Contains the compiled libraries ready for use in KiCad.
  - `3dmodels/`: 3D model files (.step, .wrl, etc.) for components.
  - `footprints/`: KiCad footprint libraries (.pretty folders).
  - `symbols/`: KiCad symbol libraries (.kicad_sym files).
- **`src/`**: Source code and raw libraries from various repositories.
  - Contains subdirectories for different library sources, such as:
    - `kicad-footprints/`: Official KiCad footprints.
    - `kicad-symbols/`: Official KiCad symbols.
    - `kicad-packages3D/`: 3D packages.
    - `SparkFun-KiCad-Libraries/`: SparkFun's KiCad libraries.
    - `ultra_librarian/`: Custom ultra librarian components.
    - `snap_magic/`: Snap magic related components.
    - And many others for specific components like LEDs, connectors, etc.
- **`utils/`**: Utility files.
  - `my_kicad_mods.code-workspace`: VS Code workspace configuration for this project.

## Prerequisites

- KiCad (version 6.0 or later recommended).
- Bash shell (for running the builder script).
- Git (for cloning submodules if any).

## Installation and Setup

1. **Clone the Repository**:

   ```
   git clone https://github.com/HenraL/my_kicad_mods.git
   cd my_kicad_mods
   ```

2. **Build the Libraries**:
   Run the builder script to compile the source libraries into the `build/` directory.

   ```
   ./builder.sh
   ```

   This script processes the source files and organizes them into footprints, symbols, and 3D models.

3. **Add to KiCad**:
   - Open KiCad.
   - Go to **Preferences > Configure Paths** and add the `build/` directory as a library path if needed.
   - In the Symbol Editor or Footprint Editor, add the libraries from `build/symbols/` and `build/footprints/`.
   - For 3D models, configure the 3D model paths to point to `build/3dmodels/`.

## Usage

- Use the built libraries in your KiCad projects by selecting symbols and footprints from the added libraries.
- For custom components, place them in appropriate subdirectories under `src/` and re-run `builder.sh`.

## Contributing

Contributions are welcome! If you have custom footprints, symbols, or 3D models:

1. Fork the repository.
2. Add your changes to the `src/` directory.
3. Update the `builder.sh` script if necessary.
4. Submit a pull request.

Please ensure that all contributions are compatible with KiCad and follow the KiCad library conventions.

## Related Repositories

This workspace includes related projects:

- **[snap_magic](https://github.com/HenraL/snap_magic)**: Specific components for snap magic applications.
- **[ultra_librarian](https://github.com/HenraL/ultra_librarian)**: Ultra librarian tools and components.

## License

This repository aggregates libraries from various sources. Please check individual source licenses in the `src/` subdirectories. Most are open-source under MIT, GPL, or similar licenses.

## Acknowledgments

- Thanks to the KiCad community for the official libraries.
- Contributions from various open-source projects and individuals.

For more information, visit the [KiCad website](https://www.kicad.org/).
