<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="order">
        <xsl:choose>
            <xsl:when test="total &lt; 10">
                (small)
            </xsl:when>
            <xsl:when test="total &lt; 20">
                (medium)
            </xsl:when>
            <xsl:otherwise>
                (large)
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>
