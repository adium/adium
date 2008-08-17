//
//  JavaCocoaAdapter.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-01.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium;

import java.net.URLClassLoader;
import java.net.URL;
import java.util.Vector;
import java.io.File;

public class JavaCocoaAdapter {
    public static ClassLoader classLoader(Vector jars, ClassLoader parent) { // Vector of String file paths
        System.err.println(jars.toString());
        
        // convert vector of strings to array of URLs
        
        URL[] urls = new URL[jars.size()];
        
        try {
            int i;
            for(i = 0; i < jars.size(); i++)
                urls[i] = new File((String)jars.elementAt(i)).toURI().toURL();
        } catch(java.net.MalformedURLException e) {
            e.printStackTrace();
            return null;
        }
        
        return URLClassLoader.newInstance(urls,(parent != null)?parent:ClassLoader.getSystemClassLoader());
    }
}
