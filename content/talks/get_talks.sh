owner=drmowinckels
repo=talks_repo

alias tac='tail -r'

# Fetch the list of folders in the "slides" directory
folders=$(gh api repos/$owner/$repo/contents/slides --jq '.[] | select(.type == "dir") | .name' | tac)

# Initialize an empty array to store JSON objects
json_array=()

convert_to_null() {
    if [ -z "$1" ]; then
        echo null
    else
        echo "\"$1\""
    fi
}

yaml_value() {
  local string="$1"
  local pattern="$2"
  echo "$string" | \
    grep "^$pattern:" | \
    sed "s/^$pattern: //" | \
    sed 's/^"//;s/"$//' | \
    sed 's/^-//;s/-$//' | \
    sed 's/^ *//;s/ *$//'
}

# Iterate over each folder
for folder in $folders; do
    echo $folder ----

    # Fetch the content from the index file in the folder
    rmd_content=$(gh api repos/$owner/$repo/contents/slides/$folder/index.Rmd --jq '.download_url' 2>/dev/null )
    qmd_content=$(gh api repos/$owner/$repo/contents/slides/$folder/index.qmd --jq '.download_url' 2>/dev/null )

    # Check if both files are not found
    if [ -z "$rmd_content" ] && [ -z "$qmd_content" ]; then
        echo "Warning: No index file found for folder $folder"
        continue
    fi

    # Check if the content is not found
    if echo "$rmd_content" | grep -q "Not Found"; then
      echo "qmd found"
      file="$qmd_content"
    else
      echo "rmd found"
      file="$rmd_content"
    fi

    file_content=$(curl -sL "$file")

    # Remove leading and trailing quotes and convert empty strings to null
    title=$(convert_to_null "$(yaml_value "$file_content" 'title')")
    date=\"$(echo $folder | cut -d'-' -f1 | sed 's/\./-/g')\"
    link=$(convert_to_null "$(yaml_value "$file_content" 'link')")

    subtitle=$(convert_to_null "$(yaml_value "$file_content" 'subtitle')")
    subtitle=$(echo $subtitle | sed 's/^-*//;s/-*$//')

    if [[ $link == null ]]; then
        link=\"https://drmowinckels.io/$repo/slides/$folder/\"
    fi

    # Extract tags from YAML front matter
    tags=$(echo "$file_content" | yq e '.tags[]')
    # Check if the string is empty or null
    if [ -z "$tags" ]; then
        tags=null
    else
        # Convert the string to a JSON array
        tags="[$(echo "$tags" | sed 's/"/\\"/g' | awk 'NF { print "\"" $0 "\"" }' | tr '\n' ',' | sed 's/,$//')]"
    fi

    thumbnail=$(convert_to_null "$(yaml_value "$file_content" 'image')")
    if [[ $thumbnail != null ]]; then
      thumbnail_strip=$(echo $thumbnail | sed s/\"//g)
      if [[ $thumbnail_strip != http* ]]; then
        thumbnail=\"https://raw.githubusercontent.com/$owner/$repo/main/slides/$folder/$thumbnail_strip\"
      fi
    fi

    button=$(convert_to_null "$(yaml_value "$file_content" 'button')")
    if [[ $button == null ]]; then
        button=\"Slides\"
    fi

    # Construct a JSON object with null values
    json_object="{
        \"title\":   $title,
        \"summary\": $subtitle,
        \"date\":    $date,
        \"image\":   $thumbnail,
        \"button\":  $button,
        \"url\":     $link,
        \"tags\":    $tags
    }"
    json_array+=("$json_object")
done

echo $json_array

# Convert the array to a JSON array
json_output="[ $(IFS=,; echo "${json_array[*]}") ]"
json_output=$(echo $json_output | jq '.')

# only save if the json array is not empty
if [[ $json_output != "[]" ]]; then
  # Write the formatted JSON to a file
  echo "$json_output" > talks.json
else
    echo "No talks found"
    exit 1
fi


