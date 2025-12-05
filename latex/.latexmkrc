# Put all auxiliary files in ./aux
$aux_dir = "aux";

# Keep output PDF in project directory
$out_dir = ".";

# Make sure aux directory exists
if ( ! -d $aux_dir ) {
    mkdir $aux_dir;
}
