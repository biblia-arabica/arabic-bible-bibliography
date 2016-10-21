<?xml version="1.0" encoding="UTF-8"?>
<!-- TEXT TO ZOTERO BIBLIOGRAPHY CONVERTER  -->
<!-- by Nathan Gibson -->
<!-- Known Limitations:
    - Entries that do not begin with [#] are not processed, or are mistakenly inserted as abstracts into another entry. 
    - Does not support series information. 
    - Encyclopedia articles are classified as book sections. 
    - Encyclopedia articles may lose volume/page information. 
    - Italics inside titles are not processed correctly. 
    - Does not support reprint information.
    - Does not support URLs.
    - The conversion attempts to add tags to entries that may be missing information, e.g., "!no title"
    - When the conversion adds manuscript tags, it flags with a "?" ones for which the format is unexpected.
    - For subject tags, the converter grabs only the one most directly above the entry.
    - Does not support the following fields:
        z:seriesEditors
        z:translators
        z:bookAuthors
        z:numberOfVolumes
        z:language
        dc:identifier -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:syriaca="http://syriaca.org" xmlns:saxon="http://saxon.sf.net/" xmlns:functx="http://www.functx.com" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:z="http://www.zotero.org/namespaces/export#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:bib="http://purl.org/net/biblio#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:vcard="http://nwalsh.com/rdf/vCard#"
    xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
    xmlns:link="http://purl.org/rss/1.0/modules/link/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml"/>
    <!-- DIRECTORY -->
    <!-- specifies where the output TEI files should go -->
    <!-- !!! Change this to where you want the output files to be placed relative to the XML file being converted. 
        This should end with a trailing slash (/).-->
    <xsl:variable name="directory"></xsl:variable>
    <!-- creates a variable containing the path of the file to be created for this record, in the location defined by $directory -->
    <xsl:variable name="filename" select="'bibliographie-zotero.xml'"/>
    
    <xsl:function name="syriaca:add-pages">
        <xsl:param name="input-nodes" as="node()*"/>
        <xsl:for-each select="$input-nodes/node()">
            <xsl:choose>
                <xsl:when test=".[node()]">
                    <xsl:copy-of select="syriaca:add-pages(node())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:analyze-string 
                        select="$input-nodes" 
                        regex="\s*pp\.\s*([0-9A-Za-z]+(\-[0-9A-Za-z]+)?)\.*">
                        <xsl:matching-substring><bib:pages><xsl:value-of select="regex-group(1)"/></bib:pages></xsl:matching-substring>
                        <xsl:non-matching-substring><xsl:copy-of select="."/></xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>   
    <xsl:function name="syriaca:split-names">
        <xsl:param name="name" as="xs:string"/>
        <xsl:analyze-string select="$name" regex="((.*),\s*(.*))|((.*)\s+(\S+))">
            <xsl:matching-substring>
                <xsl:variable name="surname" select="concat(regex-group(2),regex-group(6))"/>
                <xsl:variable name="givennname" select="concat(regex-group(3),regex-group(5))"/>
                <xsl:choose>
                    <xsl:when test="$surname or $givennname">
                        <foaf:surname><xsl:value-of select="$surname"/></foaf:surname>
                        <foaf:givenname><xsl:value-of select="$givennname"/></foaf:givenname>
                    </xsl:when>
                    <xsl:otherwise>
                        <foaf:surname><xsl:value-of select="."/></foaf:surname>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    <xsl:function name="syriaca:sanitize-titles">
        <!-- Will not preserve attributes -->
        <xsl:param name="title" as="node()*"/>
        <xsl:for-each select="$title">
            <xsl:choose>
                <xsl:when test="count(node())>1"><xsl:copy-of select="syriaca:sanitize-titles(node())"/></xsl:when>
                <xsl:otherwise>
                    <xsl:element name="{name()}">
                        <xsl:value-of select="replace(replace(node(),'^[”“,\s\.]+',''),'[,\s]+$','')"/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
    <xsl:function name="syriaca:create-flags">
        <xsl:param name="item-node"/>
        <xsl:param name="itemType"/>
        <xsl:if test="not($item-node/dc:date)"><dc:subject>!no date</dc:subject></xsl:if>
        <xsl:if test="not($item-node/bib:authors)"><dc:subject>!no author</dc:subject></xsl:if>
        <xsl:if test="not($item-node/dc:abstract)"><dc:subject>!no abstract</dc:subject></xsl:if>
        <xsl:if test="not($item-node/dc:title)"><dc:subject>!no title</dc:subject></xsl:if>
        <xsl:if test="$itemType=('journalArticle','bookSection') and not($item-node/bib:pages)"><dc:subject>!no pages</dc:subject></xsl:if>
        <xsl:if test="$itemType=('journalArticle','bookSection') and count($item-node/dc:title)=1"><dc:subject>!missing title</dc:subject></xsl:if>
        <xsl:if test="$itemType=('journalArticle') and not($item-node/prism:volume)"><dc:subject>!no volume</dc:subject></xsl:if>
        <xsl:if test="$itemType=('book','bookSection') and not($item-node/dc:publisher)"><dc:subject>!no publisher</dc:subject></xsl:if>
    </xsl:function>
    
    <xsl:function name="syriaca:add-thesis">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-thesis"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-thesis}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(3)">
                            <z:itemType>thesis</z:itemType>
                            <dc:publisher>
                                <foaf:Organization>
                                    <foaf:name><xsl:value-of select="regex-group(4)"/></foaf:name>
                                    <vcard:adr>
                                        <vcard:Address>
                                            <vcard:locality><xsl:value-of select="normalize-space(regex-group(6))"/></vcard:locality>
                                        </vcard:Address>
                                    </vcard:adr>
                                </foaf:Organization>
                            </dc:publisher>
                            <dc:date><xsl:value-of select="regex-group(7)"/></dc:date>
                            <z:type><xsl:value-of select="regex-group(3)"/></z:type>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>  
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-authors">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-authors"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-authors}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)[matches(.,'[A-Za-zÀ-ʸ]')]">
                            <bib:authors>
                                <rdf:Seq>
                                    <xsl:for-each select="tokenize(regex-group(1),'(\s+[au]nd|\s+&amp;|,)\s+')[matches(.,'[A-Za-zÀ-ʸ]')]">
                                        <rdf:li>
                                            <foaf:Person>
                                                <xsl:copy-of select="syriaca:split-names(.)"/>
                                            </foaf:Person>
                                        </rdf:li>
                                    </xsl:for-each>
                                </rdf:Seq>
                            </bib:authors>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-title">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-title"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-title}">
                    <xsl:matching-substring>
                        <xsl:choose>
                            <xsl:when test="regex-group(1)"><dc:title level="article"><xsl:copy-of select="regex-group(1)"/></dc:title></xsl:when>
                            <xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-pages">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-pages"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-pages}"> 
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <bib:pages><xsl:value-of select="regex-group(1)"/></bib:pages>
                        </xsl:if>
                        <xsl:if test="regex-group(5)">
                            <bib:pages><xsl:value-of select="regex-group(5)"/></bib:pages>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-date">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-date"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-date}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <dc:date><xsl:value-of select="regex-group(1)"/></dc:date>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-journal-volume">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-journal-volume"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-journal-volume}">
                    <xsl:matching-substring>
                        <xsl:choose>
                            <xsl:when test="regex-group(1) and regex-group(2)">
                                <dc:title><xsl:value-of select="regex-group(1)"/></dc:title>
                                <prism:volume><xsl:value-of select="regex-group(2)"/></prism:volume>
                            </xsl:when>
                            <xsl:when test="regex-group(1)">
                                <prism:volume><xsl:value-of select="regex-group(1)"/></prism:volume>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-volume">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-volume"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-volume}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <prism:volume><xsl:value-of select="regex-group(1)"/></prism:volume>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-publisher">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-publisher"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-publisher}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <dc:publisher>
                                <foaf:Organization>
                                    <vcard:adr>
                                        <vcard:Address>
                                            <vcard:locality><xsl:value-of select="regex-group(1)"/></vcard:locality>
                                        </vcard:Address>
                                    </vcard:adr>
                                    <foaf:name><xsl:value-of select="regex-group(2)"/></foaf:name>
                                </foaf:Organization>
                            </dc:publisher>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-edition">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-edition"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-edition}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <prism:edition><xsl:value-of select="replace(regex-group(1),'[\.\s]*$','')"/></prism:edition>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-editors">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-editors"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-editors}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(2)">
                            <bib:editors>
                                <rdf:Seq>
                                    <xsl:for-each select="tokenize(regex-group(2),',*\s+([au]nd|&amp;)\s+')">
                                        <rdf:li>
                                            <foaf:Person><xsl:copy-of select="syriaca:split-names(.)"/></foaf:Person>
                                        </rdf:li>
                                    </xsl:for-each>
                                </rdf:Seq>
                            </bib:editors>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-series-volume">
        <xsl:param name="input-node"/>
        <xsl:param name="regex-series-volume"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:for-each select="$input-node/node()[. instance of text()]">
                <xsl:analyze-string 
                    select="." 
                    regex="{$regex-series-volume}">
                    <xsl:matching-substring>
                        <xsl:if test="regex-group(1)">
                            <dcterms:isPartOf>
                                <bib:Series>
                                    <dc:title><xsl:value-of select="regex-group(1)"/></dc:title>
                                    <dc:identifier><xsl:value-of select="regex-group(2)"/></dc:identifier>
                                </bib:Series>
                            </dcterms:isPartOf>
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each> 
        </entry>
    </xsl:function>
    
    
    <xsl:function name="syriaca:add-mss">
        <xsl:param name="input-node"/>
        <xsl:param name="mss"/>
        <entry>
            <xsl:copy-of select="$input-node/node()"/>
            <xsl:if test="$mss">
                <xsl:variable name="mss-preface-regex" select="'^\s*(([Mm][Ss][Ss]\.?:?)|(and)?)'"/>
                <xsl:variable name="mss-city-regex" select="'(\s*(.*?),)?'"/>
                <xsl:variable name="mss-collection-regex" select="'(\s*(.*?),)?'"/>
                <xsl:variable name="mss-item-regex" select="'(\s*(.+))\s*$?'"/>
                <xsl:variable name="mss-tokenized" select="tokenize($mss,'\s*;\s*')"/>
                <xsl:for-each select="$mss-tokenized">
                    <xsl:analyze-string select="." regex="{concat($mss-preface-regex,$mss-city-regex, $mss-collection-regex,$mss-item-regex)}">
                        <xsl:matching-substring>
                            <xsl:for-each select="tokenize(regex-group(9),'(,(\sand\s)?)|\sand\s')">
                                <dc:subject><xsl:value-of select="concat('MS: ',regex-group(5),', ',regex-group(7),', ',.)"/></dc:subject>
                            </xsl:for-each>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <dc:subject>?MS: <xsl:value-of select="."/></dc:subject>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:for-each>
            </xsl:if> 
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-abstract-and-subjects">
        <xsl:param name="input-node"/>
        <xsl:param name="abstract"/>
        <xsl:param name="subject"/>
        <entry>
            <xsl:copy-of select="$input-node/node()"/>
            <xsl:if test="$abstract">
                <dcterms:abstract><xsl:value-of select="$abstract"/></dcterms:abstract>
            </xsl:if>
            <xsl:if test="$subject">
                <dc:subject>Subject: <xsl:value-of select="$subject"/></dc:subject>
            </xsl:if>
        </entry>
    </xsl:function>
    <xsl:function name="syriaca:add-uncaptured-data">
        <xsl:param name="input-node"/>
        <entry>
            <xsl:copy-of select="$input-node/node()[not(. instance of text())]"/>
            <xsl:variable name="uncaptured-data">
                <xsl:for-each select="$input-node/node()[. instance of text()]">
                    <xsl:variable name="sanitized-text" select="replace(replace(.,'^([\s\.,;“-‟&quot;\(\)\[\]]|in)+',''),'([\s\.,;“-‟&quot;\(\)\[\]]|in)+$','')"/>
                    <xsl:if test="string-length($sanitized-text)">
                        <bib:Memo>
                            <rdf:value><xsl:copy-of select="."/></rdf:value>
                        </bib:Memo>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:if test="$uncaptured-data/bib:Memo">
                <xsl:copy-of select="$uncaptured-data"/>
                <dc:subject>!uncaptured data</dc:subject>
            </xsl:if>
        </entry>
    </xsl:function>
    
    
    
    
    <!-- The number the ID tags should start with. -->
    <xsl:variable name="id-start" select="1"/>
    
    
    <xsl:template match="/tei:TEI/tei:text/tei:body">
        <xsl:result-document href="{$filename}" format="xml">
            <rdf:RDF>
                <xsl:variable name="entry-with-titles">
                    <xsl:for-each select="tei:p">
                        <entry>
                            <xsl:apply-templates/>
                        </entry>
                    </xsl:for-each>
                </xsl:variable>
                
                    <xsl:variable name="entry">
                        <xsl:for-each select="$entry-with-titles/entry[matches(.,'^\s*\[#\]')]">
                            <xsl:variable name="mss" select="following-sibling::*[matches(.,'^\s*[Mm][Ss][Ss]')][1]"/>
                            <xsl:variable name="abstract" select="following-sibling::*[1][not(matches(.,'^\s*[Mm][Ss][Ss]') or matches(.,'^\s*\[#\]'))]"/>
                            <xsl:variable name="subject" select="preceding-sibling::*[tei:anchor][1]"/><xsl:variable name="regex-volume" select="'\s*[Vv]ol\.\s*([0-9A-Za-z]+(\-[0-9A-Za-z]+)?),*'"/>
                            <xsl:variable name="regex-publisher" select="'[,\(]\s*([\w\s\.&amp;;/]+):\s*([\w\s\.&amp;;]+)'"/>
                            <xsl:variable name="regex-date" select="'\s*((14|15|16|17|18|19|20)\d{2}(\-\d+)?)(,|\)|\.\s*$)'"/>
                            <xsl:variable name="regex-pages" select="'\s*p?p\.[\s\n\t]*((([0-9A-Za-z]+(\-[0-9A-Za-z]+)?),?\s*)+)\.*|\s*(col(s|l)?\.[\s\n\t]*(([0-9A-Za-z]+(\-[0-9A-Za-z]+)?),?\s*)+)\.*'"/>
                            <xsl:variable name="regex-edition" select="',\s*([A-Za-z0-9]+\.?)\s*[Ee]d\.,?'"/>
                            <xsl:variable name="regex-editors" select="'(\[#\]|in)\s+([\w\s,À-ʸ\-\.]+?)\(eds?\.?\),?\s*'"/>
                            <xsl:variable name="regex-journal-volume" select="'(^[\s\S]*?|^)\s*(\d+\.?\d*)\s*\(*'"/>
                            <xsl:variable name="regex-series-volume" select="',\s*([\s\S]*?)\s*(\d+\.?\d*)\s*'"/>
                            <xsl:variable name="regex-authors" select="'\[#\]\s*([\w\s,À-ʸ\-\.]+)'"/>
                            <xsl:variable name="regex-article-title" select="'[“-‟&quot;]+([\s\S]*)[“-‟&quot;]+'"/>
                            <xsl:variable name="regex-translators" select="'([Ee]d\.\s+and\s+)?[Tt]rans?l?\.?\s+(and\s+[Ee]d.\s*)?(\s+by\s+)?([\w\s,À-ʸ\-\.]+?)'"/>
                            <xsl:variable name="regex-thesis" select="'([Uu]npubl(\.|ished)\s*)?([\w\.]+)[\s\-]*[Tt]hesis,\s*(.+?),(([\w\s\.,]+),)?\s*((14|15|16|17|18|19|20)\d{2}(\-\d+)?)'"/>
                            <xsl:choose>
                                <!-- Thesis -->
                                <xsl:when test="matches(.,$regex-thesis)">
                                    <xsl:variable name="thesis" select="syriaca:add-thesis(.,$regex-thesis)"/>
                                    <xsl:variable name="authors" select="syriaca:add-authors($thesis,'\[#\]\s*([\w\sÀ-ʸ\-\.]+),')"/>
                                    <xsl:variable name="title" select="syriaca:add-title($authors,',*\s*([A-Za-z]+[\s\S]*.*)+\s*')"/>
                                    <xsl:variable name="mss" select="syriaca:add-mss($title,$mss)"/>
                                    <xsl:variable name="abstract-subjects" select="syriaca:add-abstract-and-subjects($mss,$abstract,$subject)"/>
                                    <xsl:variable name="uncaptured-data" select="syriaca:add-uncaptured-data($abstract-subjects)"/>
                                    <xsl:copy-of select="$uncaptured-data"/>
                                </xsl:when>
                                <!-- Journal Article -->
                                <xsl:when test="matches(.,$regex-article-title) and matches(.,'(\d+\.?\d*)\s*\(+\s*((14|15|16|17|18|19|20)\d{2}(\-\d+)?).*\)')">
                                    <xsl:variable name="journal-article">
                                        <z:itemType>journalArticle</z:itemType>
                                        <xsl:copy-of select="node()"/>
                                    </xsl:variable>
                                    <xsl:variable name="pages" select="syriaca:add-pages($journal-article,$regex-pages)"/>
                                    <xsl:variable name="date" select="syriaca:add-date($pages,$regex-date)"/>
                                    <xsl:variable name="title" select="syriaca:add-title($date,$regex-article-title)"/>
                                    <xsl:variable name="authors" select="syriaca:add-authors($title,$regex-authors)"/>
                                    <xsl:variable name="volume" select="syriaca:add-journal-volume($authors,$regex-journal-volume)"/>
                                    <xsl:variable name="mss" select="syriaca:add-mss($volume,$mss)"/>
                                    <xsl:variable name="abstract-subjects" select="syriaca:add-abstract-and-subjects($mss,$abstract,$subject)"/>
                                    <xsl:variable name="uncaptured-data" select="syriaca:add-uncaptured-data($abstract-subjects)"/>
                                    <xsl:copy-of select="$uncaptured-data"/>
                                </xsl:when>
                                <!-- Book Section -->
                                <xsl:when test="dc:title and matches(.,$regex-article-title)">
                                    <xsl:variable name="book-section">
                                        <z:itemType>bookSection</z:itemType>
                                        <xsl:copy-of select="node()"/>                                        
                                    </xsl:variable>
                                    <xsl:variable name="pages" select="syriaca:add-pages($book-section,$regex-pages)"/>
                                    <xsl:variable name="date" select="syriaca:add-date($pages,$regex-date)"/>
                                    <xsl:variable name="volume" select="syriaca:add-volume($date,$regex-volume)"/>
                                    <xsl:variable name="publisher" select="syriaca:add-publisher($volume,$regex-publisher)"/>
                                    <xsl:variable name="edition" select="syriaca:add-edition($publisher,$regex-edition)"/>
                                    <xsl:variable name="editors" select="syriaca:add-editors($edition,$regex-editors)"/>
                                    <xsl:variable name="title" select="syriaca:add-title($editors,$regex-article-title)"/>
                                    <xsl:variable name="authors" select="syriaca:add-authors($title,$regex-authors)"/>
                                    <xsl:variable name="series-volume" select="syriaca:add-series-volume($authors,$regex-series-volume)"/>
                                    <xsl:variable name="mss" select="syriaca:add-mss($series-volume,$mss)"/>
                                    <xsl:variable name="abstract-subjects" select="syriaca:add-abstract-and-subjects($mss,$abstract,$subject)"/>
                                    <xsl:variable name="uncaptured-data" select="syriaca:add-uncaptured-data($abstract-subjects)"/>
                                    <xsl:copy-of select="$uncaptured-data"/>
                                </xsl:when>
                                <!-- Book -->
                                <xsl:when test="dc:title and not(matches(.,$regex-article-title))">
                                    <xsl:variable name="book">
                                        <z:itemType>book</z:itemType>
                                        <xsl:copy-of select="node()"/>                                        
                                    </xsl:variable>
                                    <xsl:variable name="date" select="syriaca:add-date($book,$regex-date)"/>
                                    <xsl:variable name="volume" select="syriaca:add-volume($date,$regex-volume)"/>
                                    <xsl:variable name="publisher" select="syriaca:add-publisher($volume,$regex-publisher)"/>
                                    <xsl:variable name="edition" select="syriaca:add-edition($publisher,$regex-edition)"/>
                                    <xsl:variable name="editors" select="syriaca:add-editors($edition,$regex-editors)"/>
                                    <xsl:variable name="title" select="syriaca:add-title($editors,$regex-article-title)"/>
                                    <xsl:variable name="authors" select="syriaca:add-authors($title,$regex-authors)"/>
                                    <xsl:variable name="series-volume" select="syriaca:add-series-volume($authors,$regex-series-volume)"/>
                                    <xsl:variable name="mss" select="syriaca:add-mss($series-volume,$mss)"/>
                                    <xsl:variable name="abstract-subjects" select="syriaca:add-abstract-and-subjects($mss,$abstract,$subject)"/>
                                    <xsl:variable name="uncaptured-data" select="syriaca:add-uncaptured-data($abstract-subjects)"/>
                                    <xsl:copy-of select="$uncaptured-data"/>
                                </xsl:when>
                                <!-- Unknown type -->
                                <xsl:otherwise>
                                    <xsl:variable name="book-section">
                                        <z:itemType>bookSection</z:itemType>
                                        <dc:subject>!unknown type</dc:subject>
                                        <xsl:copy-of select="node()"/>
                                    </xsl:variable>
                                    <xsl:variable name="pages" select="syriaca:add-pages($book-section,$regex-pages)"/>
                                    <xsl:variable name="date" select="syriaca:add-date($pages,$regex-date)"/>
                                    <xsl:variable name="volume" select="syriaca:add-volume($date,$regex-volume)"/>
                                    <xsl:variable name="publisher" select="syriaca:add-publisher($volume,$regex-publisher)"/>
                                    <xsl:variable name="edition" select="syriaca:add-edition($publisher,$regex-edition)"/>
                                    <xsl:variable name="editors" select="syriaca:add-editors($edition,$regex-editors)"/>
                                    <xsl:variable name="title" select="syriaca:add-title($editors,$regex-article-title)"/>
                                    <xsl:variable name="authors" select="syriaca:add-authors($title,$regex-authors)"/>
                                    <xsl:variable name="series-volume" select="syriaca:add-series-volume($authors,$regex-series-volume)"/>
                                    <xsl:variable name="mss" select="syriaca:add-mss($series-volume,$mss)"/>
                                    <xsl:variable name="abstract-subjects" select="syriaca:add-abstract-and-subjects($mss,$abstract,$subject)"/>
                                    <xsl:variable name="uncaptured-data" select="syriaca:add-uncaptured-data($abstract-subjects)"/>
                                    <xsl:copy-of select="$uncaptured-data"/>
                                </xsl:otherwise>
                                <!--<xsl:otherwise>
                                    <entry>
                                        <xsl:for-each select="node()">
                                            <xsl:choose>
                                                <xsl:when test="name()='dc:title'"><xsl:copy-of select="."/></xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:analyze-string 
                                                        select="." 
                                                        regex="{$regex-pages}"> 
                                                        <xsl:matching-substring>
                                                            <xsl:if test="regex-group(1)">
                                                                <bib:pages><xsl:value-of select="regex-group(1)"/></bib:pages>
                                                            </xsl:if>
                                                            <xsl:if test="regex-group(5)">
                                                                <bib:pages><xsl:value-of select="regex-group(5)"/></bib:pages>
                                                            </xsl:if>
                                                        </xsl:matching-substring>
                                                        <xsl:non-matching-substring>
                                                            <xsl:analyze-string 
                                                                select="." 
                                                                regex="{$regex-date}">
                                                                <xsl:matching-substring>
                                                                    <xsl:if test="regex-group(1)">
                                                                        <dc:date><xsl:value-of select="regex-group(1)"/></dc:date>
                                                                    </xsl:if>
                                                                </xsl:matching-substring>
                                                                <xsl:non-matching-substring>
                                                                    <xsl:analyze-string 
                                                                        select="." 
                                                                        regex="{$regex-volume}">
                                                                        <xsl:matching-substring>
                                                                            <xsl:if test="regex-group(1)">
                                                                                <prism:volume><xsl:value-of select="regex-group(1)"/></prism:volume>
                                                                            </xsl:if>
                                                                        </xsl:matching-substring>
                                                                        <xsl:non-matching-substring>
                                                                            <xsl:analyze-string 
                                                                                select="." 
                                                                                regex="{$regex-thesis}">
                                                                                <xsl:matching-substring>
                                                                                    <xsl:if test="regex-group(2)">
                                                                                        <z:itemType>thesis</z:itemType>
                                                                                        <dc:publisher>
                                                                                            <foaf:Organization>
                                                                                                <foaf:name><xsl:value-of select="regex-group(3)"/></foaf:name>
                                                                                                <vcard:adr>
                                                                                                    <vcard:Address>
                                                                                                        <vcard:locality><xsl:value-of select="regex-group(5)"/></vcard:locality>
                                                                                                    </vcard:Address>
                                                                                                </vcard:adr>
                                                                                            </foaf:Organization>
                                                                                        </dc:publisher>
                                                                                        <z:type><xsl:value-of select="regex-group(2)"/></z:type>
                                                                                    </xsl:if>
                                                                                </xsl:matching-substring>
                                                                                <xsl:non-matching-substring>
                                                                                    <xsl:analyze-string 
                                                                                        select="." 
                                                                                        regex="{$regex-publisher}">
                                                                                        <xsl:matching-substring>
                                                                                            <xsl:if test="regex-group(1)">
                                                                                                <dc:publisher>
                                                                                                    <foaf:Organization>
                                                                                                        <vcard:adr>
                                                                                                            <vcard:Address>
                                                                                                                <vcard:locality><xsl:value-of select="regex-group(1)"/></vcard:locality>
                                                                                                            </vcard:Address>
                                                                                                        </vcard:adr>
                                                                                                        <foaf:name><xsl:value-of select="regex-group(2)"/></foaf:name>
                                                                                                    </foaf:Organization>
                                                                                                </dc:publisher>
                                                                                            </xsl:if>
                                                                                        </xsl:matching-substring>
                                                                                        <xsl:non-matching-substring>
                                                                                            <xsl:analyze-string 
                                                                                                select="." 
                                                                                                regex="{$regex-edition}">
                                                                                                <xsl:matching-substring>
                                                                                                    <xsl:if test="regex-group(1)">
                                                                                                        <prism:edition><xsl:value-of select="regex-group(1)"/></prism:edition>
                                                                                                    </xsl:if>
                                                                                                </xsl:matching-substring>
                                                                                                <xsl:non-matching-substring>
                                                                                                    <xsl:analyze-string 
                                                                                                        select="." 
                                                                                                        regex="{$regex-editors}">
                                                                                                        <xsl:matching-substring>
                                                                                                            <xsl:if test="regex-group(2)">
                                                                                                                <bib:editors>
                                                                                                                    <rdf:Seq>
                                                                                                                        <xsl:for-each select="tokenize(regex-group(2),',*\s+([au]nd|&amp;)\s+')">
                                                                                                                            <rdf:li>
                                                                                                                                <foaf:Person><xsl:copy-of select="syriaca:split-names(.)"/></foaf:Person>
                                                                                                                            </rdf:li>
                                                                                                                        </xsl:for-each>
                                                                                                                    </rdf:Seq>
                                                                                                                </bib:editors>
                                                                                                            </xsl:if>
                                                                                                        </xsl:matching-substring>
                                                                                                        <xsl:non-matching-substring>
                                                                                                            <xsl:analyze-string 
                                                                                                                select="." 
                                                                                                                regex="{$regex-article-title}">
                                                                                                                <xsl:matching-substring>
                                                                                                                    <xsl:if test="regex-group(1)">
                                                                                                                        <dc:title><xsl:value-of select="regex-group(1)"/></dc:title>
                                                                                                                    </xsl:if>
                                                                                                                </xsl:matching-substring>
                                                                                                                <xsl:non-matching-substring>
                                                                                                                    <xsl:analyze-string 
                                                                                                                        select="." 
                                                                                                                        regex="{$regex-authors}">
                                                                                                                        <xsl:matching-substring>
                                                                                                                            <xsl:if test="regex-group(1)[matches(.,'[A-Za-zÀ-ʸ]')]">
                                                                                                                                <bib:authors>
                                                                                                                                    <rdf:Seq>
                                                                                                                                        <xsl:for-each select="tokenize(regex-group(1),'(\s+[au]nd|\s+&amp;|,)\s+')[matches(.,'[A-Za-zÀ-ʸ]')]">
                                                                                                                                            <rdf:li>
                                                                                                                                                <foaf:Person>
                                                                                                                                                    <xsl:copy-of select="syriaca:split-names(.)"/>
                                                                                                                                                </foaf:Person>
                                                                                                                                            </rdf:li>
                                                                                                                                        </xsl:for-each>
                                                                                                                                    </rdf:Seq>
                                                                                                                                </bib:authors>
                                                                                                                            </xsl:if>
                                                                                                                        </xsl:matching-substring>
                                                                                                                        <xsl:non-matching-substring>
                                                                                                                            <xsl:analyze-string 
                                                                                                                                select="." 
                                                                                                                                regex="{concat('(',$regex-series-volume,')|(',$regex-journal-volume,')')}">
                                                                                                                                <xsl:matching-substring>
                                                                                                                                    <xsl:if test="regex-group(2)">
                                                                                                                                        <dcterms:isPartOf>
                                                                                                                                            <bib:Series>
                                                                                                                                                <dc:title><xsl:value-of select="regex-group(2)"/></dc:title>
                                                                                                                                                <dc:identifier><xsl:value-of select="regex-group(3)"/></dc:identifier>
                                                                                                                                            </bib:Series>
                                                                                                                                        </dcterms:isPartOf>
                                                                                                                                    </xsl:if>
                                                                                                                                    <xsl:choose>
                                                                                                                                        <xsl:when test="regex-group(5) and regex-group(6)">
                                                                                                                                            <dc:title><xsl:value-of select="regex-group(5)"/></dc:title>
                                                                                                                                            <prism:volume><xsl:value-of select="regex-group(6)"/></prism:volume>
                                                                                                                                        </xsl:when>
                                                                                                                                        <xsl:when test="regex-group(5)">
                                                                                                                                            <prism:volume><xsl:value-of select="regex-group(5)"/></prism:volume>
                                                                                                                                        </xsl:when>
                                                                                                                                    </xsl:choose>
                                                                                                                                </xsl:matching-substring>
                                                                                                                                <xsl:non-matching-substring>
                                                                                                                                    <xsl:analyze-string select="." regex="{$regex-translators}">
                                                                                                                                        <xsl:matching-substring>
                                                                                                                                            <xsl:if test="regex-group(1)[matches(.,'[A-Za-zÀ-ʸ]')]">
                                                                                                                                                <z:translators>
                                                                                                                                                    <rdf:Seq>
                                                                                                                                                        <xsl:for-each select="tokenize(regex-group(4),'(\s+[au]nd|\s+&amp;|,)\s+')[matches(.,'[A-Za-zÀ-ʸ]')]">
                                                                                                                                                            <rdf:li>
                                                                                                                                                                <foaf:Person>
                                                                                                                                                                    <xsl:copy-of select="syriaca:split-names(.)"/>
                                                                                                                                                                </foaf:Person>
                                                                                                                                                            </rdf:li>
                                                                                                                                                        </xsl:for-each>
                                                                                                                                                    </rdf:Seq>
                                                                                                                                                </z:translators>
                                                                                                                                            </xsl:if>
                                                                                                                                        </xsl:matching-substring>
                                                                                                                                        <xsl:non-matching-substring><xsl:copy-of select="."/></xsl:non-matching-substring>
                                                                                                                                    </xsl:analyze-string>
                                                                                                                                </xsl:non-matching-substring>
                                                                                                                            </xsl:analyze-string>
                                                                                                                        </xsl:non-matching-substring>
                                                                                                                    </xsl:analyze-string>
                                                                                                                </xsl:non-matching-substring>
                                                                                                            </xsl:analyze-string>
                                                                                                        </xsl:non-matching-substring>
                                                                                                    </xsl:analyze-string>
                                                                                                </xsl:non-matching-substring>
                                                                                            </xsl:analyze-string>
                                                                                        </xsl:non-matching-substring>
                                                                                    </xsl:analyze-string>
                                                                                </xsl:non-matching-substring>
                                                                            </xsl:analyze-string>
                                                                        </xsl:non-matching-substring>
                                                                    </xsl:analyze-string>
                                                                </xsl:non-matching-substring>
                                                            </xsl:analyze-string>
                                                        </xsl:non-matching-substring>
                                                    </xsl:analyze-string>
                                                </xsl:otherwise>
                                            </xsl:choose>   
                                        </xsl:for-each>
                                        <xsl:if test="$mss">
                                            <xsl:variable name="mss-preface-regex" select="'^\s*(([Mm][Ss][Ss]\.?:?)|(and)?)'"/>
                                            <xsl:variable name="mss-city-regex" select="'(\s*(.*?),)?'"/>
                                            <xsl:variable name="mss-collection-regex" select="'(\s*(.*?),)?'"/>
                                            <xsl:variable name="mss-item-regex" select="'(\s*(.+))\s*$?'"/>
                                            <xsl:variable name="mss-tokenized" select="tokenize($mss,'\s*;\s*')"/>
                                            <xsl:for-each select="$mss-tokenized">
                                                <xsl:analyze-string select="." regex="{concat($mss-preface-regex,$mss-city-regex, $mss-collection-regex,$mss-item-regex)}">
                                                    <xsl:matching-substring>
                                                        <xsl:for-each select="tokenize(regex-group(9),'(,(\sand\s)?)|\sand\s')">
                                                            <dc:subject><xsl:value-of select="concat('MS: ',regex-group(5),', ',regex-group(7),', ',.)"/></dc:subject>
                                                        </xsl:for-each>
                                                    </xsl:matching-substring>
                                                    <xsl:non-matching-substring>
                                                        <dc:subject>?MS: <xsl:value-of select="."/></dc:subject>
                                                    </xsl:non-matching-substring>
                                                </xsl:analyze-string>
                                            </xsl:for-each>
                                            
                                        </xsl:if>
                                        <xsl:if test="$abstract">
                                            <dcterms:abstract><xsl:value-of select="$abstract"/></dcterms:abstract>
                                        </xsl:if>
                                        <xsl:if test="$subject">
                                            <dc:subject>Subject: <xsl:value-of select="$subject"/></dc:subject>
                                        </xsl:if>
                                    </entry>
                                </xsl:otherwise>-->
                            </xsl:choose>
                            
                            
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:variable name="entries-including-uncaptured-data">
                        <xsl:for-each select="$entry/entry">
                            <xsl:copy-of select="syriaca:add-uncaptured-data(.)"/>
                        </xsl:for-each>
                    </xsl:variable>
                
                    
                    <xsl:for-each select="$entries-including-uncaptured-data/entry">
                        <xsl:variable name="this-entry" select="."/>
                        <xsl:variable name="id-num" select="$id-start+position()-1"/>
                        <xsl:variable name="id"><dc:subject><xsl:value-of select="concat('ID: ',$id-num)"/></dc:subject></xsl:variable>
                        <xsl:variable name="contributors-all">
                            <xsl:copy-of select="bib:authors"/>
                            <xsl:copy-of select="bib:editors"/>
                            <!--<z:seriesEditors>
                                    <rdf:Seq>
                                        <rdf:li>
                                            <foaf:Person>
                                                <foaf:surname>Series EditorL</foaf:surname>
                                                <foaf:givenname>SeriesF I</foaf:givenname>
                                            </foaf:Person>
                                        </rdf:li>
                                    </rdf:Seq>
                                </z:seriesEditors>-->
                            <!--<z:translators>
                                    <rdf:Seq>
                                        <rdf:li>
                                            <foaf:Person>
                                                <foaf:surname>TranslatorL</foaf:surname>
                                                <foaf:givenname>TranslatorF I</foaf:givenname>
                                            </foaf:Person>
                                        </rdf:li>
                                    </rdf:Seq>
                                </z:translators>-->
                            <!-- Do we need the following? -->
                            <!--<z:bookAuthors>
                                <rdf:Seq>
                                    <rdf:li>
                                        <foaf:Person>
                                            <foaf:surname>Book AuthorL</foaf:surname>
                                            <foaf:givenname>BookF I</foaf:givenname>
                                        </foaf:Person>
                                    </rdf:li>
                                </rdf:Seq>
                            </z:bookAuthors>-->
                        </xsl:variable>
                        <xsl:variable name="publication-info">
                            <xsl:copy-of select="dc:publisher"/>
                            <xsl:copy-of select="dcterms:abstract"/>
                            <!--<z:numberOfVolumes># of Volumes</z:numberOfVolumes>-->
                            <xsl:copy-of select="prism:edition"/>
                            <xsl:copy-of select="dc:date"/>
                            <xsl:copy-of select="bib:pages"/>
                            <!--<z:language>Language</z:language>-->
                            <!--<dc:identifier>
                            <dcterms:URI><rdf:value>URL</rdf:value></dcterms:URI>
                        </dc:identifier>-->
                        </xsl:variable>
                        <xsl:variable name="tags">
                            <xsl:copy-of select="$id"/>
                            <xsl:copy-of select="dc:subject"/>
                        </xsl:variable>
                        <xsl:variable name="notes">
                            <xsl:for-each select="bib:Memo">
                                <bib:Memo rdf:about="#note_{$id-num}-{position()}">
                                    <xsl:copy-of select="node()"/>
                                </bib:Memo>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:variable name="note-references">
                            <xsl:for-each select="$notes/bib:Memo">
                                <dcterms:isReferencedBy rdf:resource="{@rdf:about}"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="z:itemType='thesis'">
                                <bib:Thesis>
                                    <xsl:variable name="itemType" select="'thesis'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title)"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="z:type"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                    <xsl:copy-of select="$note-references"/>
                                </bib:Thesis>
                                <xsl:copy-of select="$notes"/>
                            </xsl:when>
                            <!-- Book section -->
                            <xsl:when test="z:itemType='bookSection' and not(dc:subject='!unknown type')">
                                <bib:BookSection>
                                    <xsl:variable name="itemType" select="'bookSection'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Book>
                                            <xsl:copy-of select="dcterms:isPartOf[bib:Series]"/>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[not(@level='article')])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Book>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[@level='article'])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                    <xsl:copy-of select="$note-references"/>
                                </bib:BookSection>
                                <xsl:copy-of select="$notes"/>
                            </xsl:when>
                            <!-- Journal article -->
                            <xsl:when test="z:itemType='journalArticle'">
                                <bib:Article>
                                    <xsl:variable name="itemType" select="'journalArticle'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Journal>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[not(@level='article')])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Journal>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[@level='article'])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                    <xsl:copy-of select="$note-references"/>
                                </bib:Article>
                                <xsl:copy-of select="$notes"/>
                            </xsl:when>
                            <xsl:when test="z:itemType='book'">
                                <bib:Book>
                                    <xsl:variable name="itemType" select="'book'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <xsl:copy-of select="dcterms:isPartOf[bib:Series]"/>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title)"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="prism:volume"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                    <xsl:copy-of select="$note-references"/>
                                </bib:Book>
                                <xsl:copy-of select="$notes"/>
                            </xsl:when>
                            <!-- Unknown item type -->
                            <!-- !!! This seems to be catching things that should be regular book section instead. E.g., Walid Saleh, An Islamic Diatessaron -->
                            <xsl:otherwise>
                                <bib:BookSection>
                                    <xsl:variable name="itemType" select="'bookSection'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Book>
                                            <xsl:copy-of select="dcterms:isPartOf[bib:Series]"/>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[not(@level='article')])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Book>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[@level='article'])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                    <xsl:copy-of select="$note-references"/>
                                </bib:BookSection>
                                <xsl:copy-of select="$notes"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="//tei:hi[@rend='italic']">
        <!-- !!! This doesn't handle italics inside article titles. E.g., Mark Swanson, “Ibn Taymiyya and the <hi rend="italic">Kitāb al-burhān</hi>. A
            Muslim controversialist responds to a ninth-century Arabic Christian apology,” -->
        <dc:title><xsl:copy-of select="node()"></xsl:copy-of></dc:title>
    </xsl:template>
    <!-- preserves anchors -->
    <xsl:template match="//tei:anchor">
        <xsl:copy-of select="."/>
    </xsl:template>
        
</xsl:stylesheet>