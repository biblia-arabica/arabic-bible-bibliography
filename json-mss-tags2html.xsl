<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml"/>
    <xsl:template match="/JSON">
        <xsl:variable name="all-rows" select="rows"/>
        <xsl:variable name="collections" select="distinct-values(rows/City_Collection)"/>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>Manuscript references related to Arabic Bible translations recorded in the Bibliography of the Arabic Bible</title>
            </head>
            <body>
                <h1>Manuscript references related to Arabic Bible translations recorded in the <a href="https://biblia-arabica.com/bibl">Bibliography of the Arabic Bible</a></h1>
                <xsl:for-each select="$collections">
                    <xsl:variable name="current-collection" select="."/>
                    <xsl:variable name="current-rows" select="$all-rows[City_Collection = $current-collection]"/>
                    <h2><xsl:value-of select="."/> (<xsl:value-of select="count(distinct-values($current-rows))"/>)</h2>
                    <xsl:variable name="mss">
                        <xsl:for-each select="$current-rows">
                            <xs:row>
                                <xsl:if test="Prefix!='null'">
                                    <xsl:value-of select="Prefix,' '"/>
                                </xsl:if>
                                <xsl:value-of select="Shelfmark"/>
                            </xs:row>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="mss-sorted">
                        <xsl:for-each select="$mss/xs:row">
                            <xsl:sort select="."/>
                            <xsl:copy-of select="."/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:copy-of select="string-join((distinct-values($mss-sorted/xs:row)),', ')"/>
                </xsl:for-each>
            </body>
        </html>        
    </xsl:template>
</xsl:stylesheet>
