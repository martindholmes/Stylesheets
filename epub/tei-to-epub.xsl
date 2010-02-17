<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" exclude-result-prefixes="tei dc html">
  <xsl:import href="../xhtml2/tei.xsl"/>
  <xsl:output method="xml" encoding="utf-8" indent="yes"/>
  <xsl:key name="GRAPHICS" use="1" match="tei:graphic"/>
  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet">
    <desc>
      <p>
	TEI stylesheet for making ePub output. A lot learnt from
	http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html and
	the stylesheets of the NZETC.
      </p>
      <p>
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
	
      </p>
      <p>Author: See AUTHORS</p>
      <p>Id: $Id$</p>
      <p>Copyright: 2008, TEI Consortium</p>
    </desc>
  </doc>
  <xsl:param name="splitLevel">0</xsl:param>
  <xsl:param name="STDOUT">false</xsl:param>
  <xsl:param name="outputDir">OEBPS</xsl:param>
  <xsl:param name="cssFile">../tei.css</xsl:param>
  <xsl:param name="cssPrintFile">../tei-print.css</xsl:param>
  <xsl:param name="cssODDFile">../odd.css</xsl:param>
  <xsl:param name="topNavigationPanel">false</xsl:param>
  <xsl:param name="bottomNavigationPanel">false</xsl:param>
  <xsl:param name="autoToc">false</xsl:param>
  <xsl:param name="tocDepth">1</xsl:param>
  <xsl:param name="linkPanel">false</xsl:param>
  <xsl:param name="institution"/>
  <xsl:param name="uid"/>
  <xsl:param name="odd">true</xsl:param>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Suppress normal page footer      </desc>
   </doc>
  <xsl:template name="stdfooter"/>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Set licence</desc>
   </doc>
  <xsl:template name="generateLicence">
    <xsl:text>Creative Commons Attribution</xsl:text>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Set language</desc>
   </doc>
  <xsl:template name="generateLanguage">
    <xsl:choose>
      <xsl:when test="@xml:lang">
	<xsl:value-of select="@xml:lang"/>
      </xsl:when>
      <xsl:when test="tei:text/@xml:lang">
	<xsl:value-of select="tei:text/@xml:lang"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>en</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Set name of publisher</desc>
   </doc>
  <xsl:template name="generatePublisher">
    <xsl:value-of select="normalize-space(tei:teiHeader/tei:fileDesc/tei:publicationStmt)"/>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Set unique identifier for output
      </desc>
   </doc>
  <xsl:template name="generateID">
    <xsl:choose>
      <xsl:when test="$uid=''">
        <xsl:text>http://www.example.com/TEIEPUB/</xsl:text>
        <xsl:value-of select="format-dateTime(current-dateTime(),'[Y][M02][D02][H02][M02][s02]')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$uid"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Override addition of CSS links. We force a simple
      name of "stylesheet.css"
      </desc>
   </doc>
  <xsl:template name="includeCSS">
    <link xmlns="http://www.w3.org/1999/xhtml" href="stylesheet.css" rel="stylesheet" type="text/css"/>
    <xsl:if test="not($cssPrintFile='')">
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" media="print" type="text/css" href="print.css"/>
    </xsl:if>
    <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="application/vnd.adobe-page-template+xml" href="page-template.xpgt"/>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Override of top-level template. This does most of
      the work: performing the normal transformation, fixing the links to graphics files so that they are
      all relative, creating the extra output files, etc</desc>
   </doc>
  <xsl:template match="/">
    <xsl:variable name="stage1">
      <xsl:apply-templates mode="fixgraphics"/>
    </xsl:variable>
    <xsl:for-each select="$stage1">
      <xsl:apply-templates mode="split"/>
      <xsl:for-each select="*">
        <xsl:variable name="TOC">
          <TOC xmlns="http://www.w3.org/1999/xhtml">
            <xsl:call-template name="mainTOC"/>
          </TOC>
        </xsl:variable>
        <xsl:result-document method="text" href="OEBPS/stylesheet.css">
          <xsl:for-each select="tokenize(unparsed-text($cssFile),
				'\r?\n')">
	    <xsl:call-template name="purgeCSS"/>
          </xsl:for-each>
          <xsl:if test="$odd='true'">
            <xsl:for-each select="tokenize(unparsed-text($cssODDFile),         '\r?\n')">
	      <xsl:call-template name="purgeCSS"/>
            </xsl:for-each>
          </xsl:if>
        </xsl:result-document>
        <xsl:result-document method="text" href="OEBPS/print.css">
          <xsl:for-each select="tokenize(unparsed-text($cssPrintFile),       '\r?\n')">
	    <xsl:call-template name="purgeCSS"/>
          </xsl:for-each>
        </xsl:result-document>
        <xsl:result-document method="text" href="mimetype">
          <xsl:text>application/epub+zip</xsl:text>
        </xsl:result-document>
        <xsl:result-document method="xml" href="META-INF/container.xml">
          <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
            <rootfiles>
              <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
          </container>
        </xsl:result-document>
        <xsl:result-document href="OEBPS/content.opf" method="xml">
          <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="dcidid" version="2.0">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:opf="http://www.idpf.org/2007/opf">
              <dc:title>
                <xsl:call-template name="generateTitle"/>
              </dc:title>
              <dc:language xsi:type="dcterms:RFC3066">
                <xsl:call-template name="generateLanguage"/>
              </dc:language>
              <dc:identifier id="dcidid" opf:scheme="URI">
                <xsl:call-template name="generateID"/>
              </dc:identifier>
              <dc:creator>
                <xsl:call-template name="generateAuthor"/>
              </dc:creator>
              <dc:publisher>
                <xsl:call-template name="generatePublisher"/>
              </dc:publisher>
              <dc:date xsi:type="dcterms:W3CDTF">
                <xsl:call-template name="generateDate"/>
              </dc:date>
              <dc:rights>
                <xsl:call-template name="generateLicence"/>
              </dc:rights>
            </metadata>
            <manifest>
              <item id="stylesheet.css" href="stylesheet.css" media-type="text/css"/>
              <item id="print.css" href="print.css" media-type="text/css"/>
              <xsl:if test="$odd='true'">
                <item id="odd.css" href="odd.css" media-type="text/css"/>
              </xsl:if>
              <item id="head" href="index.html" media-type="application/xhtml+xml"/>
              <xsl:for-each select="$TOC/html:TOC/html:ul/html:li">
                <xsl:choose>
                  <xsl:when test="html:a">
                    <item href="{html:a[1]/@href}" media-type="application/xhtml+xml">
                      <xsl:attribute name="id">
                        <xsl:text>section</xsl:text>
                        <xsl:number count="html:li" level="any"/>
                      </xsl:attribute>
                    </item>
                  </xsl:when>
                  <xsl:when test="html:ul">
                    <xsl:for-each select="html:ul/html:li">
                      <item href="{html:a[1]/@href}" media-type="application/xhtml+xml">
                        <xsl:attribute name="id">
                          <xsl:text>section</xsl:text>
                          <xsl:number count="html:li" level="any"/>
                        </xsl:attribute>
                      </item>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
		</xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
              <!-- images -->
              <xsl:for-each select="key('GRAPHICS',1)">
                <xsl:variable name="ID">
                  <xsl:number level="any"/>
                </xsl:variable>
                <xsl:variable name="mimetype">
                  <xsl:choose>
                    <xsl:when test="contains(@url,'.gif')">image/gif</xsl:when>
                    <xsl:when test="contains(@url,'.png')">image/png</xsl:when>
                    <xsl:otherwise>image/jpeg</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <item href="{@url}" id="image-{$ID}" media-type="{$mimetype}"/>
              </xsl:for-each>
              <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
            </manifest>
            <spine toc="ncx">
              <itemref idref="head"/>
              <xsl:for-each select="$TOC/html:TOC/html:ul/html:li">
                <xsl:choose>
                  <xsl:when test="html:a">
                    <itemref>
                      <xsl:attribute name="idref">
                        <xsl:text>section</xsl:text>
                        <xsl:number count="html:li" level="any"/>
                      </xsl:attribute>
                    </itemref>
                  </xsl:when>
                  <xsl:when test="html:ul">
                    <xsl:for-each select="html:ul/html:li">
                      <itemref>
                        <xsl:attribute name="idref">
                          <xsl:text>section</xsl:text>
                          <xsl:number count="html:li" level="any"/>
                        </xsl:attribute>
                      </itemref>
                    </xsl:for-each>
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </spine>
            <guide>
              <reference type="text" title="Text" href="index.html"/>
              <xsl:for-each select="$TOC/html:TOC/html:ul/html:li">
                <xsl:choose>
                  <xsl:when test="html:a">
                    <reference type="text" href="{html:a[1]/@href}">
                      <xsl:attribute name="title">
                        <xsl:value-of select="normalize-space(html:a[1])"/>
                      </xsl:attribute>
                    </reference>
                  </xsl:when>
                  <xsl:when test="html:ul">
                    <xsl:for-each select="html:ul/html:li">
                      <reference type="text" href="{html:a/@href}">
                        <xsl:attribute name="title">
                          <xsl:value-of select="normalize-space(html:a[1])"/>
                        </xsl:attribute>
                      </reference>
                    </xsl:for-each>
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </guide>
          </package>
        </xsl:result-document>
        <xsl:result-document href="OEBPS/toc.ncx" method="xml">
          <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
            <head>
              <meta name="dtb:uid">
                <xsl:attribute name="content">
                  <xsl:call-template name="generateID"/>
                </xsl:attribute>
              </meta>
              <meta name="dtb:totalPageCount" content="0"/>
              <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            <docTitle>
              <text>
                <xsl:call-template name="generateTitle"/>
              </text>
            </docTitle>
            <navMap>
              <navPoint id="navPoint-1" playOrder="1">
                <navLabel>
                  <text>Titlepage</text>
                </navLabel>
                <content src="index.html"/>
              </navPoint>
              <xsl:for-each select="$TOC/html:TOC/html:ul/html:li">
                <xsl:choose>
                  <xsl:when test="html:a">
                    <navPoint id="navPoint-{position()}" playOrder="{position()+1}">
                      <navLabel>
                        <text>
                          <xsl:value-of select="normalize-space(html:a[1])"/>
                        </text>
                      </navLabel>
                      <content src="{html:a/@href}"/>
                    </navPoint>
                  </xsl:when>
                  <xsl:when test="html:ul">
                    <xsl:for-each select="html:ul/html:li">
                      <navPoint id="navPoint-{position()}" playOrder="{position()+1}">
                        <navLabel>
                          <text>
                            <xsl:value-of select="normalize-space(html:a[1])"/>
                          </text>
                        </navLabel>
                        <content src="{html:a/@href}"/>
                      </navPoint>
                    </xsl:for-each>
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </navMap>
          </ncx>
        </xsl:result-document>
        <xsl:result-document method="xml" href="OEBPS/page-template.xpgt">
          <ade:template xmlns="http://www.w3.org/1999/xhtml" xmlns:ade="http://ns.adobe.com/2006/ade" xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
              <fo:simple-page-master master-name="single_column">
                <fo:region-body margin-bottom="3pt" margin-top="0.5em" margin-left="3pt" margin-right="3pt"/>
              </fo:simple-page-master>
              <fo:simple-page-master master-name="single_column_head">
                <fo:region-before extent="8.3em"/>
                <fo:region-body margin-bottom="3pt" margin-top="6em" margin-left="3pt" margin-right="3pt"/>
              </fo:simple-page-master>
              <fo:simple-page-master master-name="two_column" margin-bottom="0.5em" margin-top="0.5em" margin-left="0.5em" margin-right="0.5em">
                <fo:region-body column-count="2" column-gap="10pt"/>
              </fo:simple-page-master>
              <fo:simple-page-master master-name="two_column_head" margin-bottom="0.5em" margin-left="0.5em" margin-right="0.5em">
                <fo:region-before extent="8.3em"/>
                <fo:region-body column-count="2" margin-top="6em" column-gap="10pt"/>
              </fo:simple-page-master>
              <fo:simple-page-master master-name="three_column" margin-bottom="0.5em" margin-top="0.5em" margin-left="0.5em" margin-right="0.5em">
                <fo:region-body column-count="3" column-gap="10pt"/>
              </fo:simple-page-master>
              <fo:simple-page-master master-name="three_column_head" margin-bottom="0.5em" margin-top="0.5em" margin-left="0.5em" margin-right="0.5em">
                <fo:region-before extent="8.3em"/>
                <fo:region-body column-count="3" margin-top="6em" column-gap="10pt"/>
              </fo:simple-page-master>
              <fo:page-sequence-master>
                <fo:repeatable-page-master-alternatives>
                  <fo:conditional-page-master-reference master-reference="three_column_head" page-position="first" ade:min-page-width="80em"/>
                  <fo:conditional-page-master-reference master-reference="three_column" ade:min-page-width="80em"/>
                  <fo:conditional-page-master-reference master-reference="two_column_head" page-position="first" ade:min-page-width="50em"/>
                  <fo:conditional-page-master-reference master-reference="two_column" ade:min-page-width="50em"/>
                  <fo:conditional-page-master-reference master-reference="single_column_head" page-position="first"/>
                  <fo:conditional-page-master-reference master-reference="single_column"/>
                </fo:repeatable-page-master-alternatives>
              </fo:page-sequence-master>
            </fo:layout-master-set>
            <ade:style>
              <ade:styling-rule selector=".title_box" display="adobe-other-region" adobe-region="xsl-region-before"/>
            </ade:style>
          </ade:template>
        </xsl:result-document>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Add specific linebreak in verbatim output, as
      readers do not seem to grok the CSS
      </desc>
   </doc>
  <xsl:template name="verbatim-lineBreak">
    <xsl:param name="id"/>
    <br/>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Local mode to rewrite names of graphics inclusions;
      default is identity transform
      </desc>
   </doc>
  <xsl:template match="@*|text()|comment()|processing-instruction()" mode="fixgraphics">
    <xsl:copy-of select="."/>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Local mode to rewrite names of graphics inclusions;
      default is identifty transform
      </desc>
   </doc>
  <xsl:template match="*" mode="fixgraphics">
    <xsl:copy>
      <xsl:apply-templates
	  select="*|@*|processing-instruction()|comment()|text()" mode="fixgraphics"/>
    </xsl:copy>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Local mode to rewrite names of graphics inclusions
      </desc>
   </doc>
  <xsl:template match="tei:graphic" mode="fixgraphics">
    <xsl:copy>
      <xsl:variable name="newName">
        <xsl:text>media/image</xsl:text>
        <xsl:number level="any"/>
        <xsl:text>.</xsl:text>
        <xsl:value-of select="tokenize(@url,'\.')[last()]"/>
      </xsl:variable>
      <xsl:attribute name="url">
        <xsl:value-of select="$newName"/>
      </xsl:attribute>
      <xsl:copy-of select="@n"/>
      <xsl:copy-of select="@height"/>
      <xsl:copy-of select="@width"/>
      <xsl:copy-of select="@scale"/>
    </xsl:copy>
  </xsl:template>

  <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
      <desc>[epub] Remove unwanted things from CSS
      </desc>
   </doc>
  <xsl:template name="purgeCSS">
    <xsl:choose>
      <xsl:when test="contains(.,'clear:')"/>
      <xsl:when test="contains(.,'float:')"/>
      <xsl:when test="contains(.,'font-size:')"/>
      <xsl:when test="contains(.,'line-height:')"/>
      <xsl:when test="contains(.,'max-width:')"/>
      <xsl:when test="contains(.,'width:')"/>
      <xsl:when test="contains(.,'height:')"/>
      <xsl:when test="contains(.,'text-indent:')"/>
      <xsl:when test="contains(.,'margin')"/>
      <xsl:when test="contains(.,'border')"/>
      <xsl:when test="contains(.,'padding')"/>
      <xsl:otherwise>
	<xsl:value-of select="."/>
	<xsl:text>&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>