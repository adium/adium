<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xalan="http://xml.apache.org/xslt">

  <xsl:output method="html"
              encoding="ascii"
              indent="yes"
              xalan:indent-amount="2"
              doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
              doctype-system="http://www.w3.org/TR/html4/transitional.dtd"/>
  <xsl:template match="page">
    <html>
      <head>
        <title><xsl:value-of select="title" /></title>
        <link rel="stylesheet" type="text/css" href="stylesheet.css" />
      </head>
      <body>
        <div id="container">
          <div id="banner">
            <h2 class="titlebar">
              <xsl:value-of select="title" />
            </h2>
          </div>
          <div id="sidebar-a">
            <h4>SQL Logger<br /></h4>
              <a href="index.html" class="sidebar">Home</a>
              <br /><a href="http://www.visualdistortion.org/sqllogger/screenshots.jsp" class="offsides">Screenshots</a>
              <br /><a href="install.html"
                class="sidebar">Installation</a>
              <br /><a href="technical.html" class="sidebar">Technical
              Details</a>
              <br /><a href="performance.html"
              class="sidebar">Maintenance/Performance</a>
            <br /><a href="changes.txt" class="offsides">Changelog</a>
            <br /><a
              href="http://www.visualdistortion.org/sqllogger/sqllogger.tar.gz"
              class="offsides"><b>JSP/HTML package</b></a>

              <br /><h4>Adium</h4>
              <a href="http://www.adiumx.com/" class="offsides">Adium</a>
              <br /><a href="http://forums.adiumx.com"
                class="offsides">Adium
                Forums</a>
                <br /><a href="http://planet.adiumx.com"
                class="offsides">Planet Adium</a>
                <br /><a href="http://cia.navi.cx/stats/project/adium/"
                class="offsides">SVN Changes</a>
              <br /><a
                href="http://www.visualdistortion.org/sqllogger/adium-sql.tar.gz"
                class="offsides"><b>Adium Plugin (.63)</b></a>
              <br /><a
              href="http://www.visualdistortion.org/sqllogger/SQL_Logger_70.tar.gz"
              class="offsides"><b>Adium Plugin (.70)</b></a>
              <br/>

              <h4>Fire</h4>
              <a href="http://fire.sourceforge.net" class="offsides">Fire</a>
              <br /><h4>PostgreSQL</h4>
              <a href="http://www.postgresql.org" class="offsides">PostgreSQL</a>
              <br /><a
                href="http://www.postgresql.org/docs/7.4/interactive/index.html"
                class="offsides">PgSQL Documentation</a>
              <br /><a
              href="http://www.xceltech.net/products/freeware_products.html"
              class="offsides">PostMan Query</a>
              <br />
              <h4>Visual Distortion</h4>
              <a href="http://www.visualdistortion.org/"
              class="offsides">Visual Distortion Home</a>
          </div>
          <div id="content">
            <xsl:apply-templates select="body"/>
          </div>
          <div id="footer">
            <xsl:value-of select="title" /><br />
            <a
              href="mailto:jmelloy@visualdistortion.org">jmelloy@visualdistortion.org</a>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="body">
    <xsl:copy-of select="*"/>
  </xsl:template>
</xsl:stylesheet>
