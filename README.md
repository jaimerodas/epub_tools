 # EPUB Tools

**TL;DR:** A collection of scripts to extract, split, and compile EPUBs from multiple source EPUB files containing collections of chapters. Use these tools to build a single consolidated EPUB book.

## Prerequisites
Developed using Ruby 3.4.3. Ensure you have the correct Ruby version installed:

```bash
rbenv install 3.4.3
rbenv local 3.4.3
```

 Install required gems:
 ```bash
 bundle install
 ```

 ## Files

### xhtml_extractor.rb
Extracts all `.xhtml` files (excluding `nav.xhtml`) from one or more `.epub` files in a source directory into a target directory.
Usage:
```bash
ruby xhtml_extractor.rb <source_epub_dir> <target_xhtml_dir>
```

### split_chapters.rb
Splits a single XHTML file into individual chapter files based on chapter or prologue markers. Uses `text_style_class_finder.rb` and `xhtml_cleaner.rb` internally.
Usage:
```bash
ruby split_chapters.rb <input.xhtml> "Book Title" [output_dir] [prefix]
```

### text_style_class_finder.rb
Helper script that scans an XHTML document for text style class definitions (used by `split_chapters.rb`). Had to do this as the EPUB files I'm working with come from GoogleDocs and that generates inline styling and weird classes.

### xhtml_cleaner.rb
Cleans up and formats an XHTML file for consistency (used by `split_chapters.rb`).

### add_chapters_to_epub.rb
Moves chapter `.xhtml` files into an EPUB's `OEBPS` directory, updates `package.opf` manifest & spine, and inserts entries into `nav.xhtml`.
Usage:
```bash
ruby add_chapters_to_epub.rb <chapters_dir> <epub_oebps_dir>
```

### epub_initializer.rb
Initializes a basic EPUB directory structure (`META-INF`, `OEBPS`), creates `mimetype`, `container.xml`, `package.opf`, `nav.xhtml`, `title.xhtml`, and copies `style.css`.
Usage:
```bash
ruby epub_initializer.rb "Book Title" "Author Name" <output_epub_dir> <cover_image_path>
```

### make_epub.sh
Zips up an EPUB directory into a `.epub` file, ensuring `mimetype` is uncompressed and first.
Usage:
```bash
./make_epub.sh <epub_folder> [output.epub]
```

### compile_book.sh
High-level script that orchestrates the full flow: extraction, splitting, initialization, adding chapters, and final packaging.
Usage:
```bash
./compile_book.sh "Book Title" "Author Name" <source_epubs_dir> [output.epub] [cover_image.jpg]
```

### style.css
Default CSS file applied to all XHTML content.

 ## Example

 ```bash
 ./compile_book.sh "My Novel" "Jane Doe" ./source_epubs My_Novel.epub
 ```

 This will produce `My_Novel.epub` in the current directory.

## Testing
you have the required gems (nokogiri and rubyzip), then:

```bash
rake test
```
