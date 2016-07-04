<%@ page import="java.util.*,
                   java.io.*,
                   javax.jcr.*,
                   javax.jcr.query.*,
                   org.apache.commons.lang.*,
                   org.apache.jackrabbit.util.Text,
                   org.slf4j.Logger,
                   org.apache.sling.api.resource.*,
                   org.apache.sling.commons.json.*,
                   org.apache.sling.commons.json.JSONException,
                   org.apache.sling.commons.json.io.JSONWriter,
                   org.apache.sling.jcr.resource.JcrResourceUtil,
				   org.apache.jackrabbit.commons.JcrUtils,
                   com.day.cq.commons.jcr.*" 
%><%@ include file="/libs/foundation/global.jsp" %><%

String contentType = request.getHeader("content-type");
String path = request.getParameter("path");

String version = request.getParameter("version"); //9 or 10 , 10 for x
if (version == null) {
    version = "10";
}

JSONWriter writer = new JSONWriter(slingResponse.getWriter());
writer.setTidy(true);
writer.object();

ResourceResolver rr = slingRequest.getResourceResolver();
Session session = rr.adaptTo(Session.class);
JSONObject obj = new JSONObject(new ReaderJSONTokener(slingRequest.getReader()));

Iterator<String> it = obj.keys();

if (session.itemExists(path + "/jcr:content")) {
    Node node = session.getNode(path + "/jcr:content");
    String resourceType = node.getProperty("sling:resourceType").getString();
    if (!resourceType.contains("components/data/json/jsonpage")) {
        writer.key("success").value(false);
        writer.key("reason").value("the page is not a jsonfile page");       
    } else {
        if(node != null) {
            for(Node n : JcrUtils.getChildNodes(node)) {
                n.remove();
            }
            node.save();
            Builder builder = new Builder(node, version);
            builder.build(obj, builder.getRoot());
            builder.save();
        }
        writer.key("success").value(true);
    }
} else {
    writer.key("succss").value(false);
    writer.key("reason").value("can't find the path. do nothing.");
}
writer.endObject();
%><%!

    public class Builder {
    	private String version;
    	private Node jcr;
    	private Node root;
        public Builder(Node jcr, String version) {
            this.jcr = jcr;
			this.version = version;
            buildRoot();
        }

    	public Node getRoot() {
            return this.root;
    	}

    	public void save() {
            try {
            	this.jcr.save();
            } catch(Exception e) {
            }
    	}

    	private void buildRoot() {
            try {
            	Node object = this.jcr.addNode("10".equals(this.version) ? "object" : "items");
				object.setProperty("sling:resourceType","10".equals(this.version) ? "originx/components/data/json/jsonobject" : "origin/components/data/json/jsonobject");            	
                this.root = object.addNode("items");
            	this.root.setProperty("sling:resourceType", "foundation/components/parsys");
                this.jcr.save();

            } catch(Exception e) {

            }
    	}

    	public void build(JSONObject obj, Node node) throws Exception {
			int pos = 0;
            Iterator<String> it = obj.keys();
            while(it.hasNext()) {
                String key = it.next();
                Object o = obj.get(key);
                if ( o instanceof JSONObject) {
					Node items = saveKeyObject(node, pos++, key);
                    build((JSONObject)o, items);
                } else if (o instanceof String) {
                    String value = obj.getString(key);
                    if (node != null) {
						saveKeyValuePair(node, pos++, key, value);
                    }
                } else if (o instanceof JSONArray) {
                    JSONArray arr = obj.getJSONArray(key);
					saveKeyArray(node, pos++, key, arr);
                }
            }

		}

    	private void saveKeyArray(Node root, Integer pos, String key, JSONArray arr) throws Exception {
            Node items = saveKey(root, pos, key);

            for(int i=0; i<arr.length(); i++) {
                String s = arr.getString(i);
                String nodeName = i == 0 ? "jsonstring" : String.format("jsonstring_%d", pos -1); 
				saveString(items, nodeName, s);
            }
    	}


    	private Node saveKeyObject(Node root, Integer pos, String key) throws Exception {
            Node items = saveKey(root, pos, key);

            Node jsonobj = items.addNode("jsonobject");
            jsonobj.setProperty("sling:resourceType","10".equals(this.version) ? "originx/components/data/json/jsonobject" : "origin/components/data/json/jsonobject");  

            Node jsonobjectItems = jsonobj.addNode("items");
            jsonobjectItems.setProperty("sling:resourceType", "foundation/components/parsys");
            return jsonobjectItems;
        }

        private void saveKeyValuePair(Node root, Integer pos, String key, String value) throws Exception {
            Node items = saveKey(root, pos, key);
			saveString(items, "jsonstring", value);
        }

    	private void saveString(Node items, String nodeName, String value) throws Exception {
            Node n = items.addNode(nodeName);
            n.setProperty("sling:resourceType", "10".equals(this.version) ? "originx/components/data/json/jsonstring" : "origin/components/data/json/jsonstring");
            Node i18n = n.addNode("i18n");
            i18n.setProperty("value", value);
    	}

    	private Node saveKey(Node node, Integer pos, String key) throws Exception {
            String nodeName = pos == 0 ? "jsonkey" : String.format("jsonkey_%d", pos -1);

            Node k = node.addNode(nodeName);
            k.setProperty("key", key);
            k.setProperty("sling:resourceType", "10".equals(this.version) ? "originx/components/data/json/jsonkey" : "origin/components/data/json/jsonkey");

            Node items = k.addNode("items"); 
            items.setProperty("sling:resourceType", "foundation/components/parsys");
			return items;
        }

	}

    public static String getPostData(HttpServletRequest req) {
        StringBuilder sb = new StringBuilder();
        try {
            BufferedReader reader = req.getReader();
            reader.mark(10000);

            String line;

 			while ((line = reader.readLine()) != null) {
            	sb.append(line).append("\n");
         	}    

            reader.reset();
            // do NOT close the reader here, or you won't be able to get the post data twice
        } catch(IOException e) {
            //logger.warn("getPostData couldn't.. get the post data", e);  // This has happened if the request's reader is closed    
        }

        return sb.toString();
    }

    /**
     * Copy from http://www.JSON.org/java/org/json/JSONTokener.java
     * that adds support for passing a Reader instead of just a String
     * as the old JSONTokener class in org.apache.sling.commons.json does.
     */
    public static class ReaderJSONTokener extends JSONTokener {

        private int index;
        private Reader reader;
        private char lastChar;
        private boolean useLastChar;


        /**
         * Construct a JSONTokener from a string.
         *
         * @param reader     A reader.
         */
        public ReaderJSONTokener(Reader reader) {
            super(null);
            this.reader = reader.markSupported() ? 
            		reader : new BufferedReader(reader);
            this.useLastChar = false;
            this.index = 0;
        }


        /**
         * Construct a JSONTokener from a string.
         *
         * @param s     A source string.
         */
        public ReaderJSONTokener(String s) {
            this(new StringReader(s));
        }


        /**
         * Back up one character. This provides a sort of lookahead capability,
         * so that you can test for a digit or letter before attempting to parse
         * the next number or identifier.
         */
        public void back() {
            if (useLastChar || index <= 0) {
                return;
                //throw new JSONException("Stepping back two steps is not supported");
            }
            index -= 1;
            useLastChar = true;
        }



        /**
         * Get the hex value of a character (base16).
         * @param c A character between '0' and '9' or between 'A' and 'F' or
         * between 'a' and 'f'.
         * @return  An int between 0 and 15, or -1 if c was not a hex digit.
         */
        public static int dehexchar(char c) {
            if (c >= '0' && c <= '9') {
                return c - '0';
            }
            if (c >= 'A' && c <= 'F') {
                return c - ('A' - 10);
            }
            if (c >= 'a' && c <= 'f') {
                return c - ('a' - 10);
            }
            return -1;
        }


        /**
         * Determine if the source string still contains characters that next()
         * can consume.
         * @return true if not yet at the end of the source.
         */
        public boolean more() {
            char nextChar = next();
            if (nextChar == 0) {
                return false;
            } 
            back();
            return true;
        }


        /**
         * Get the next character in the source string.
         *
         * @return The next character, or 0 if past the end of the source string.
         */
        public char next() {
            if (this.useLastChar) {
            	this.useLastChar = false;
                if (this.lastChar != 0) {
                	this.index += 1;
                }
                return this.lastChar;
            } 
            int c;
            try {
                c = this.reader.read();
            } catch (IOException exc) {
                return 0;
                //throw new JSONException(exc);
            }

            if (c <= 0) { // End of stream
            	this.lastChar = 0;
                return 0;
            } 
        	this.index += 1;
        	this.lastChar = (char) c;
            return this.lastChar;
        }


        /**
         * Consume the next character, and check that it matches a specified
         * character.
         * @param c The character to match.
         * @return The character.
         * @throws JSONException if the character does not match.
         */
        public char next(char c) throws JSONException {
            char n = next();
            if (n != c) {
                throw syntaxError("Expected '" + c + "' and instead saw '" +
                        n + "'");
            }
            return n;
        }


        /**
         * Get the next n characters.
         *
         * @param n     The number of characters to take.
         * @return      A string of n characters.
         * @throws JSONException
         *   Substring bounds error if there are not
         *   n characters remaining in the source string.
         */
         public String next(int n) throws JSONException {
             if (n == 0) {
                 return "";
             }

             char[] buffer = new char[n];
             int pos = 0;

             if (this.useLastChar) {
            	 this.useLastChar = false;
                 buffer[0] = this.lastChar;
                 pos = 1;
             }

             try {
                 int len;
                 while ((pos < n) && ((len = reader.read(buffer, pos, n - pos)) != -1)) {
                     pos += len;
                 }
             } catch (IOException exc) {
                 throw new JSONException(exc);
             }
             this.index += pos;

             if (pos < n) {
                 throw syntaxError("Substring bounds error");
             }

             this.lastChar = buffer[n - 1];
             return new String(buffer);
         }


        /**
         * Get the next char in the string, skipping whitespace.
         * @throws JSONException
         * @return  A character, or 0 if there are no more characters.
         */
        public char nextClean() throws JSONException {
            for (;;) {
                char c = next();
                if (c == 0 || c > ' ') {
                    return c;
                }
            }
        }


        /**
         * Return the characters up to the next close quote character.
         * Backslash processing is done. The formal JSON format does not
         * allow strings in single quotes, but an implementation is allowed to
         * accept them.
         * @param quote The quoting character, either
         *      <code>"</code>&nbsp;<small>(double quote)</small> or
         *      <code>'</code>&nbsp;<small>(single quote)</small>.
         * @return      A String.
         * @throws JSONException Unterminated string.
         */
        public String nextString(char quote) throws JSONException {
            char c;
            StringBuffer sb = new StringBuffer();
            for (;;) {
                c = next();
                switch (c) {
                case 0:
                case '\n':
                case '\r':
                    throw syntaxError("Unterminated string");
                case '\\':
                    c = next();
                    switch (c) {
                    case 'b':
                        sb.append('\b');
                        break;
                    case 't':
                        sb.append('\t');
                        break;
                    case 'n':
                        sb.append('\n');
                        break;
                    case 'f':
                        sb.append('\f');
                        break;
                    case 'r':
                        sb.append('\r');
                        break;
                    case 'u':
                        sb.append((char)Integer.parseInt(next(4), 16));
                        break;
                    case '"':
                    case '\'':
                    case '\\':
                    case '/':
                    	sb.append(c);
                    	break;
                    default:
                        throw syntaxError("Illegal escape.");
                    }
                    break;
                default:
                    if (c == quote) {
                        return sb.toString();
                    }
                    sb.append(c);
                }
            }
        }


        /**
         * Get the text up but not including the specified character or the
         * end of line, whichever comes first.
         * @param  d A delimiter character.
         * @return   A string.
         */
        public String nextTo(char d) {
            StringBuffer sb = new StringBuffer();
            for (;;) {
                char c = next();
                if (c == d || c == 0 || c == '\n' || c == '\r') {
                    if (c != 0) {
                        back();
                    }
                    return sb.toString().trim();
                }
                sb.append(c);
            }
        }


        /**
         * Get the text up but not including one of the specified delimiter
         * characters or the end of line, whichever comes first.
         * @param delimiters A set of delimiter characters.
         * @return A string, trimmed.
         */
        public String nextTo(String delimiters) {
            char c;
            StringBuffer sb = new StringBuffer();
            for (;;) {
                c = next();
                if (delimiters.indexOf(c) >= 0 || c == 0 ||
                        c == '\n' || c == '\r') {
                    if (c != 0) {
                        back();
                    }
                    return sb.toString().trim();
                }
                sb.append(c);
            }
        }


        /**
         * Get the next value. The value can be a Boolean, Double, Integer,
         * JSONArray, JSONObject, Long, or String, or the JSONObject.NULL object.
         * @throws JSONException If syntax error.
         *
         * @return An object.
         */
        public Object nextValue() throws JSONException {
            char c = nextClean();
            String s;

            switch (c) {
                case '"':
                case '\'':
                    return nextString(c);
                case '{':
                    back();
                    return new JSONObject(this);
                case '[':
                case '(':
                    back();
                    return new JSONArray(this);
            }

            /*
             * Handle unquoted text. This could be the values true, false, or
             * null, or it can be a number. An implementation (such as this one)
             * is allowed to also accept non-standard forms.
             *
             * Accumulate characters until we reach the end of the text or a
             * formatting character.
             */

            StringBuffer sb = new StringBuffer();
            while (c >= ' ' && ",:]}/\\\"[{;=#".indexOf(c) < 0) {
                sb.append(c);
                c = next();
            }
            back();

            s = sb.toString().trim();
            if (s.equals("")) {
                throw syntaxError("Missing value");
            }
            return stringToValue(s);
        }


        /**
         * Skip characters until the next character is the requested character.
         * If the requested character is not found, no characters are skipped.
         * @param to A character to skip to.
         * @return The requested character, or zero if the requested character
         * is not found.
         */
        public char skipTo(char to) {
            char c;
            try {
                int startIndex = this.index;
                reader.mark(Integer.MAX_VALUE);
                do {
                    c = next();
                    if (c == 0) {
                        reader.reset();
                        this.index = startIndex;
                        return c;
                    }
                } while (c != to);
            } catch (IOException exc) {
                return 0;
                //throw new JSONException(exc);
            }

            back();
            return c;
        }

        /**
         * Make a JSONException to signal a syntax error.
         *
         * @param message The error message.
         * @return  A JSONException object, suitable for throwing
         */
        public JSONException syntaxError(String message) {
            return new JSONException(message + toString());
        }


        /**
         * Make a printable string of this JSONTokener.
         *
         * @return " at character [this.index]"
         */
        public String toString() {
            return " at character " + index;
        }
        
        // ---------------------------------------------------------------
        // Taken from newer JSONObject.stringToValue()

        /**
         * Try to convert a string into a number, boolean, or null. If the string
         * can't be converted, return the string.
         * @param s A String.
         * @return A simple JSON value.
         */
        static public Object stringToValue(String s) {
            if (s.equals("")) {
                return s;
            }
            if (s.equalsIgnoreCase("true")) {
                return Boolean.TRUE;
            }
            if (s.equalsIgnoreCase("false")) {
                return Boolean.FALSE;
            }
            if (s.equalsIgnoreCase("null")) {
                return JSONObject.NULL;
            }

            /*
             * If it might be a number, try converting it. We support the 0- and 0x-
             * conventions. If a number cannot be produced, then the value will just
             * be a string. Note that the 0-, 0x-, plus, and implied string
             * conventions are non-standard. A JSON parser is free to accept
             * non-JSON forms as long as it accepts all correct JSON forms.
             */

            char b = s.charAt(0);
            if ((b >= '0' && b <= '9') || b == '.' || b == '-' || b == '+') {
                if (b == '0') {
                    if (s.length() > 2 &&
                            (s.charAt(1) == 'x' || s.charAt(1) == 'X')) {
                        try {
                            return new Integer(Integer.parseInt(s.substring(2),
                                    16));
                        } catch (Exception e) {
                            /* Ignore the error */
                        }
                    } else {
                        try {
                            return new Integer(Integer.parseInt(s, 8));
                        } catch (Exception e) {
                            /* Ignore the error */
                        }
                    }
                }
                try {
                    if (s.indexOf('.') > -1 || s.indexOf('e') > -1 || s.indexOf('E') > -1) {
                        return Double.valueOf(s);
                    } else {
                        Long myLong = new Long(s);
                        if (myLong.longValue() == myLong.intValue()) {
                            return new Integer(myLong.intValue());
                        } else {
                            return myLong;
                        }
                    }
                }  catch (Exception f) {
                    /* Ignore the error */
                }
            }
            return s;
        }
    }

%>