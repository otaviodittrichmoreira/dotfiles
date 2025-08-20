#!/usr/bin/env bash

mapfile -t lines

entries=()

i=0
while [ $i -lt ${#lines[@]} ]; do

    exp=""
    while [[ ! "${lines[$i]}" =~ \`\`\`bash* ]]; do
        exp+="${lines[$i]} "
        ((i++))
    done

    # insert delimiter
    exp+=",,,"

    ((i++))
    # Capture everything inside the code block
    while [[ ! "${lines[$i]}" =~ ^\`\`\` ]]; do
        exp+="${lines[$i]}; "
        ((i++))
    done
    # Remove last ;
    exp="${exp::-2}"
    # Remove :
    exp=$(echo $exp | tr -d ':')
    entries+=("$exp")
    ((i++))

done



# Use fzf to select a command with preview showing explanation
echo $(printf "%s\n" "${entries[@]}" | \
    fzf \
    --delimiter ",,,"  \
    --with-nth 2.. \
    --accept-nth 2.. \
    --preview="echo {1}" \
    --preview-window="wrap,follow,up"
)
