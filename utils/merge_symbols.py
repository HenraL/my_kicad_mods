#!/usr/bin/env python3
"""
Merge multiple KiCad symbol library files into a single combined file.
Properly handles nested sub-symbols and normalizes indentation.
"""

import sys
import re
from pathlib import Path


def count_parens(text):
    """Count net parentheses in a string."""
    count = 0
    for char in text:
        if char == '(':
            count += 1
        elif char == ')':
            count -= 1
    return count


def normalize_indent(text):
    """Convert tabs to spaces (8-space tab stops)."""
    return text.expandtabs(8)


def extract_symbols(file_path):
    """
    Extract all top-level symbol definitions from a KiCad symbol library file.
    Returns a list of (symbol_name, symbol_lines) tuples.
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Normalize tabs to spaces in all lines
    lines = [normalize_indent(line.rstrip('\n\r')) for line in lines]
    
    symbols = []
    in_symbol = False
    current_symbol_lines = []
    symbol_name = None
    depth = 0
    
    for line_num, line in enumerate(lines, 1):
        # Skip the kicad_symbol_lib header
        if '(kicad_symbol_lib' in line:
            continue
        
        # Skip empty lines outside symbols
        if not in_symbol and not line.strip():
            continue
        
        # Detect top-level symbol start
        if not in_symbol:
            match = re.match(r'^\s*\(symbol\s+"([^"]+)"', line)
            if match:
                in_symbol = True
                symbol_name = match.group(1)
                current_symbol_lines = [line]
                depth = count_parens(line)
                continue
        
        if in_symbol:
            current_symbol_lines.append(line)
            depth += count_parens(line)
            
            # When depth returns to 0, the symbol is complete
            if depth == 0:
                symbols.append((symbol_name, current_symbol_lines))
                in_symbol = False
                current_symbol_lines = []
                symbol_name = None
    
    return symbols


def normalize_symbol_indentation(symbol_lines):
    """
    Normalize indentation of a symbol to use 2 spaces per level.
    """
    if not symbol_lines:
        return []
    
    # Find the base indentation of the first line
    first_line = symbol_lines[0]
    match = re.match(r'^(\s*)', first_line)
    base_indent = len(match.group(1)) if match else 0
    
    # Detect the indentation unit from nested content
    indent_unit = None
    for line in symbol_lines[1:]:
        stripped = line.lstrip()
        if stripped:
            current_indent = len(line) - len(stripped)
            if current_indent > base_indent:
                indent_unit = current_indent - base_indent
                break
    
    if indent_unit is None or indent_unit < 1:
        indent_unit = 2
    
    # Normalize each line
    normalized_lines = []
    for line in symbol_lines:
        stripped = line.lstrip()
        if not stripped:
            normalized_lines.append('')
            continue
        
        current_indent = len(line) - len(stripped)
        relative_indent = current_indent - base_indent
        nesting_level = relative_indent // indent_unit
        
        # New indent: 2 spaces for top-level, then 2 spaces per nesting level
        new_indent = 2 + (nesting_level * 2)
        if new_indent < 2:
            new_indent = 2
        
        normalized_lines.append(' ' * new_indent + stripped)
    
    return normalized_lines


def merge_symbol_files(input_files, output_file):
    """
    Merge multiple KiCad symbol library files into one combined file.
    
    Args:
        input_files: List of input file paths
        output_file: Output file path
    """
    all_symbols = []
    
    # Extract symbols from all input files
    for input_file in input_files:
        if not Path(input_file).exists():
            print(f"Warning: File not found: {input_file}", file=sys.stderr)
            continue
        
        try:
            symbols = extract_symbols(input_file)
            for name, symbol_lines in symbols:
                # Normalize indentation
                normalized_lines = normalize_symbol_indentation(symbol_lines)
                all_symbols.append((name, normalized_lines))
                print(f"Extracted symbol: {name} from {Path(input_file).name}")
        except Exception as e:
            print(f"Error processing {input_file}: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
            continue
    
    # Write combined file
    with open(output_file, 'w', encoding='utf-8') as f:
        # Write header
        f.write('(kicad_symbol_lib (version 20211014) (generator kicad_symbol_editor)\n')
        
        # Write all symbols
        for name, lines in all_symbols:
            for line in lines:
                f.write(line + '\n')
        
        # Write closing paren
        f.write(')\n')
    
    print(f"\nMerged {len(all_symbols)} symbols into {output_file}")


def main():
    if len(sys.argv) < 3:
        print("Usage: merge_symbols.py <output_file> <input_file1> [input_file2] ...", file=sys.stderr)
        sys.exit(1)
    
    output_file = sys.argv[1]
    input_files = sys.argv[2:]
    
    merge_symbol_files(input_files, output_file)


if __name__ == '__main__':
    main()
