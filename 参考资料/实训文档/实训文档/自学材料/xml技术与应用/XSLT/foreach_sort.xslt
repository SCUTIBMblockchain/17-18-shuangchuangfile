<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/"> 
        <xsl:apply-templates select="//Company"/>
    </xsl:template>
    <xsl:template match="Company">
        <xsl:for-each select="Person/Name">
            <xsl:sort select="."/>
            <li><xsl:value-of select="."/></li>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
