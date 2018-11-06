<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <xsl:comment>
            <xsl:text>Processing instruction should appear next</xsl:text>
        </xsl:comment>
        <xsl:processing-instruction name="xml-stylesheet">
            <xsl:text>type="text/xsl" href="some.xslt"</xsl:text>
        </xsl:processing-instruction>
        <xsl:copy-of select="."/>
    </xsl:template>
</xsl:stylesheet> 