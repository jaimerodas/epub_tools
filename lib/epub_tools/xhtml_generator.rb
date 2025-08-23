# frozen_string_literal: true

module EpubTools
  # Generates XHTML content for EPUB files
  class XhtmlGenerator
    attr_accessor :cover_image_fname

    def initialize(title:, author:)
      @title = title
      @author = author
      @cover_image_fname = nil
    end

    # Generates title page XHTML content
    def build_title_page
      <<~XHTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <meta charset="UTF-8" />
            <title>#{@title}</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <h1 class="title">#{@title}</h1>
            <p class="author">by #{@author}</p>
          </body>
        </html>
      XHTML
    end

    # Generates cover page XHTML content
    def build_cover_page
      <<~XHTML
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
          <head>
            <meta charset="UTF-8" />
            <title>Cover</title>
            <link rel="stylesheet" type="text/css" href="style.css"/>
          </head>
          <body>
            <div class="cover-image">
              <img src="#{@cover_image_fname}" alt="Cover"/>
            </div>
          </body>
        </html>
      XHTML
    end

    # Generates navigation XHTML content
    def build_nav_page
      <<~XHTML
        <?xml version="1.0" encoding="utf-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
          <head>
            <title>Table of Contents</title>
          </head>
          <body>
            <nav epub:type="toc" id="toc">
              <h1>Table of Contents</h1>
              <ol>
                <li><a href="title.xhtml">Title Page</a></li>
              </ol>
            </nav>
          </body>
        </html>
      XHTML
    end
  end
end
