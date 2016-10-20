<?xml version="1.0" encoding="UTF-8"?>
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
                
                
<!--                    Tried to use the following to process abstracts, but haven't figured out how to properly capture them yet. -->
<!--                <xsl:for-each select="tei:p[starts-with(.,'[#]') or preceding-sibling::*[starts-with(.,'[#]')]]">-->
                    
                    <!--<xsl:variable name="entry-with-titles">
                        <entry>
                                <xsl:apply-templates/>
                        </entry>
                    </xsl:variable>-->
                    <xsl:variable name="entry">
                        <xsl:for-each select="$entry-with-titles/entry[matches(.,'^\s*\[#\]')]">
                            <xsl:variable name="mss" select="following-sibling::*[matches(.,'^\s*[Mm][Ss][Ss]')][1]"/>
                            <xsl:variable name="abstract" select="following-sibling::*[not(matches(.,'^\s*[Mm][Ss][Ss]') or matches(.,'^\s*\[#\]'))][1]"/>
                            <entry>
                            <xsl:for-each select="node()">
                                    <xsl:choose>
                                        <xsl:when test="name()='dc:title'"><xsl:copy-of select="."/></xsl:when>
                                        <xsl:otherwise>
                                            <xsl:variable name="regex-volume" select="'\s*[Vv]ol\.\s*([0-9A-Za-z]+(\-[0-9A-Za-z]+)?),*'"/>
                                            <!-- !!! This doesn't catch the place if there is no publisher name. 
                                            Also fails if there is a slash, e.g., (Leiden/Boston: Brill, 2008) -->
                                            <xsl:variable name="regex-publisher" select="'[,\(]\s*([\w\s\.&amp;;]+):\s*([\w\s\.&amp;;]+)'"/>
                                            <xsl:variable name="regex-date" select="'\s*((14|15|16|17|18|19|20)\d{2}(\-\d+)?)(,|\))'"/>
                                            <xsl:variable name="regex-pages" select="'\s*p?p\.[\s\n\t]*((([0-9A-Za-z]+(\-[0-9A-Za-z]+)?),?\s*)+)\.*'"/>
                                            <xsl:variable name="regex-edition" select="',\s*([A-Za-z0-9]+\.?)\s*ed\.,?'"/>
                                            <xsl:variable name="regex-editors" select="'(\[#\]|in)\s+([\w\s,À-ʸ\-\.]+?)\(eds?\.?\),?\s*'"/>
                                            <xsl:variable name="regex-journal-volume" select="'(^[\s\S]*?|^)\s*(\d+\.?\d*)\s*\(*$'"/>
                                            <xsl:variable name="regex-authors" select="'\[#\]\s*([\w\s,À-ʸ\-\.]+)'"/>
                                            <xsl:variable name="regex-article-title" select="'[“-‟&quot;]+([\s\S]*)[“-‟&quot;]+'"/>
                                            
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
                                                                regex="{$regex-pages}">
                                                                <xsl:matching-substring>
                                                                    <xsl:if test="regex-group(1)">
                                                                        <bib:pages><xsl:value-of select="regex-group(1)"/></bib:pages>
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
                                                                                                                        regex="{$regex-journal-volume}">
                                                                                                                        <xsl:matching-substring>
                                                                                                                            <xsl:if test="regex-group(1)">
                                                                                                                                <dc:title><xsl:value-of select="regex-group(1)"/></dc:title>
                                                                                                                            </xsl:if>
                                                                                                                            <xsl:if test="regex-group(2)">
                                                                                                                                <prism:volume><xsl:value-of select="regex-group(2)"/></prism:volume>
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
                            </entry>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:for-each select="$entry/entry">
                        <xsl:variable name="id"><dc:subject><xsl:value-of select="concat('ID: ',$id-start+position()-1)"/></dc:subject></xsl:variable>
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
                        <xsl:choose>
                            <!-- Book section -->
                            <xsl:when test="count(dc:title)=2 and bib:pages and bib:editors and (dc:date|dc:publisher)">
                                <bib:BookSection>
                                    <xsl:variable name="itemType" select="'bookSection'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Book>
                                            <dcterms:isPartOf>
                                                <bib:Series>
                                                    <dc:title>Series</dc:title>
                                                    <dc:identifier>Series Number</dc:identifier>
                                                </bib:Series>
                                            </dcterms:isPartOf>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[2])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Book>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[1])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                </bib:BookSection>
                            </xsl:when>
                            <!-- Journal article -->
                            <xsl:when test="count(dc:title)=2 and (prism:volume|dc:date) and not(bib:editors|dc:publisher)">
                                <bib:Article>
                                    <xsl:variable name="itemType" select="'journalArticle'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Journal>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[2])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Journal>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[1])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                </bib:Article>
                            </xsl:when>
                            <xsl:when test="count(dc:title)=1 and not(bib:pages) and (dc:date|dc:publisher)">
                                <bib:Book>
                                    <xsl:variable name="itemType" select="'book'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Series>
                                            <dc:title>Series</dc:title>
                                            <dc:identifier>Series Number</dc:identifier>
                                        </bib:Series>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title)"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="prism:volume"/>
                                    <xsl:copy-of select="$tags"/>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                </bib:Book>
                            </xsl:when>
                            <!-- Unknown item type -->
                            <!-- !!! This seems to be catching things that should be regular book section instead. E.g., Walid Saleh, An Islamic Diatessaron -->
                            <xsl:otherwise>
                                <bib:BookSection>
                                    <xsl:variable name="itemType" select="'bookSection'"/>
                                    <z:itemType><xsl:value-of select="$itemType"/></z:itemType>
                                    <dcterms:isPartOf>
                                        <bib:Book>
                                            <dcterms:isPartOf>
                                                <bib:Series>
                                                    <dc:title>Series</dc:title>
                                                    <dc:identifier>Series Number</dc:identifier>
                                                </bib:Series>
                                            </dcterms:isPartOf>
                                            <xsl:copy-of select="syriaca:sanitize-titles(dc:title[2])"/>
                                            <xsl:copy-of select="prism:volume"/>
                                        </bib:Book>
                                    </dcterms:isPartOf>
                                    <xsl:copy-of select="$contributors-all"/>
                                    <xsl:copy-of select="syriaca:sanitize-titles(dc:title[1])"/>
                                    <xsl:copy-of select="$publication-info"/>
                                    <xsl:copy-of select="$tags"/>
                                    <dc:subject>!unknown type</dc:subject>
                                    <xsl:copy-of select="syriaca:create-flags(.,$itemType)"/>
                                </bib:BookSection>
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
        
</xsl:stylesheet>

<!-- Knutsson entries are not showing up.
Reprint -->