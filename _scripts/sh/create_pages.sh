#!/usr/bin/env bash
#
# Create HTML pages for Categories and Tags in posts.
#
# Usage:
#     Call from the '_posts' sibling directory.
#
# v2.2
# https://github.com/cotes2020/jekyll-theme-chirpy
# © 2020 Cotes Chung
# Published under MIT License

set -eu

TYPE_CATEGORY=0
TYPE_TAG=1

category_count=0
tag_count=0

# Print one value per line for a plural or singular front matter key.
# A value can be a list or a single string.
_read_list() {
  yq --front-matter=extract e "[.$2 // .$3 // []] | flatten | .[]" "$1"
}

read_categories() {
  _read_list "$1" categories category
}

read_tags() {
  _read_list "$1" tags tag
}

init() {

  if [[ -d categories ]]; then
    rm -rf categories
  fi

  if [[ -d tags ]]; then
    rm -rf tags
  fi

  if [[ ! -d _posts ]]; then
    exit 0
  fi

  mkdir categories tags
}

create_category() {
  if [[ -n $1 ]]; then
    local _name=$1
    local _filepath="categories/$(echo "$_name" | sed 's/ /-/g' | awk '{print tolower($0)}').html"

    if [[ ! -f $_filepath ]]; then
      echo "---" > "$_filepath"
      echo "layout: category" >> "$_filepath"
      echo "title: $_name" >> "$_filepath"
      echo "category: $_name" >> "$_filepath"
      echo "---" >> "$_filepath"

      ((category_count = category_count + 1))
    fi
  fi
}

create_tag() {
  if [[ -n $1 ]]; then
    local _name=$1
    local _filepath="tags/$(echo "$_name" | sed "s/ /-/g;s/'//g" | awk '{print tolower($0)}').html"

    if [[ ! -f $_filepath ]]; then

      echo "---" > "$_filepath"
      echo "layout: tag" >> "$_filepath"
      echo "title: $_name" >> "$_filepath"
      echo "tag: $_name" >> "$_filepath"
      echo "---" >> "$_filepath"

      ((tag_count = tag_count + 1))
    fi
  fi
}

#########################################
# Create HTML pages for Categories/Tags.
# Arguments:
#   $1 - an array string
#   $2 - type specified option
#########################################
create_pages() {
  if [[ -n $1 ]]; then
    # split string to array
    IFS_BAK=$IFS
    IFS=$'\n'
    local _string=$1

    case $2 in

      $TYPE_CATEGORY)
        for i in $_string; do
          create_category "$i"
        done
        ;;

      $TYPE_TAG)
        for i in $_string; do
          create_tag "$i"
        done
        ;;

      *) ;;

    esac

    IFS=$IFS_BAK
  fi

}

main() {
  # Without yq every page is skipped silently, so stop here instead.
  if ! command -v yq > /dev/null; then
    echo "[ERROR] yq is required to create category and tag pages." >&2
    exit 1
  fi

  init

  for _file in $(find "_posts" -type f \( -iname \*.md -o -iname \*.markdown \)); do
    local _categories=$(read_categories "$_file")
    local _tags=$(read_tags "$_file")

    create_pages "$_categories" $TYPE_CATEGORY
    create_pages "$_tags" $TYPE_TAG
  done

  if [[ $category_count -gt 0 ]]; then
    echo "[INFO] Succeed! $category_count category-pages created."
  fi

  if [[ $tag_count -gt 0 ]]; then
    echo "[INFO] Succeed! $tag_count tag-pages created."
  fi
}

main
