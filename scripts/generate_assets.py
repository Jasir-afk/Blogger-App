import os

def generate_assets():
    assets_dir = 'assets'
    output_file = 'lib/gen/assets.dart'
    
    if not os.path.exists(assets_dir):
        print("Assets directory not found.")
        return

    content = [
        "// ignore_for_file: constant_identifier_names",
        "",
        "class Assets {",
        "  Assets._();",
        ""
    ]
    
    subdirs = [d for d in os.listdir(assets_dir) if os.path.isdir(os.path.join(assets_dir, d))]
    
    for subdir in subdirs:
        class_name = subdir.capitalize()
        content.append(f"  static const {subdir} = _Assets{class_name}();")
        
    content.append("}")
    content.append("")
    
    for subdir in subdirs:
        class_name = subdir.capitalize()
        content.append(f"class _Assets{class_name} {{")
        content.append(f"  const _Assets{class_name}();")
        content.append("")
        
        subdir_path = os.path.join(assets_dir, subdir)
        files = [f for f in os.listdir(subdir_path) if os.path.isfile(os.path.join(subdir_path, f))]
        
        for file in files:
            # Skip hidden files and system files
            if file.startswith('.'): continue
            
            # Clean name for variable (remove extension, replace special chars)
            var_name = os.path.splitext(file)[0].replace('-', '_').replace(' ', '_')
            path = f"assets/{subdir}/{file}".replace('\\', '/')
            content.append(f"  final String {var_name} = '{path}';")
            
        content.append("}")
        content.append("")

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as f:
        f.write("\n".join(content))
    print(f"Generated {output_file}")

if __name__ == "__main__":
    generate_assets()
