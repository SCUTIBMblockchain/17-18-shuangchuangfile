<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:import href="utility.xslt"/>
    <xsl:variable name="author" select="'Tom and Jerry'"/>
    <xsl:template match="/">
        <output>
            <xsl:call-template name="AddComment"/>
        </output>
    </xsl:template>
</xsl:stylesheet>
