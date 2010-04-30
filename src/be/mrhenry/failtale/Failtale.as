package be.mrhenry.failtale
{
	import be.mrhenry.utils.CapabilitiesGrabber;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.operations.SplitParagraphOperation;

	/**
	 * 
	 * @author Bram Plessers
	 * 
	 */
	public class Failtale
	{
		/**
		 * @public
		 * contains the last request xml
		 */
		public var lastRequest : XML;
		 
		/**
		 * @public
		 * contains the last result xml
		 */
		public var lastResult : XML;
		
		/**
		 * @private
		 * your api-key: get one from www.failtale.be
		 */
		private var __api : String = "get your API key from www.failtale.be";
		
		/**
		 * @private
		 * the url of the Failtale instance: www.failtale.be
		 * you can install / run your own instance: http://github.com/mrhenry/failtale
		 * no trailing slash
		 */
		private var __url : String = "http://define-your-url-in-the-init-method";
		
		/**
		 * @private keeps track of the singleton instance
		 */
		private static var __instance : Failtale;
		
		/**
		 * @private
		 * contains a list of callbacks triggered when we receive a result from the server
		 */
		private var __callback : Function;
		
		
		/**
		 * @private
		 * contains a list of occured errors to prevent flooding your Failtale server with the same
		 * error over and over again ( max. count = 5 in a Flash Player session )
		 * open close the website / app to reset this counter
		 */ 
		private var __errors : Dictionary = new Dictionary(true);
		
		/**
		 * @private
		 * max. number of times the same error is sent to the failtale server 
		 */ 
		private const MAX_OCCURENCES_SENT_TO_SERVER_IN_ONE_SESSION : int = 5;
		
		
		/**
		 * 
		 * @param e initialize a Failtale instance using Failtale.getInstance()
		 * 
		 */
		public function Failtale( e : Enforcer )
		{
			
		}
		
		public function log( failtaleModel : FailtaleModel, callback : Function = null ) : void
		{
			
			
			failtaleModel.api = __api;
			
			__callback = callback;
			
			var fm : FailtaleModel = failtaleModel;
			
			// check if the error has occured before in this session
			// if so: don't send the error to the server
			var a : Array = fm.error.getStackTrace().toString().split("\n");
			//var errorName : String = a[1].split("[")[1].split("]")[0];
			var errorName : String = a[0];
			
			if( __errors[errorName] == null )
			{
				__errors[errorName] = 1;
			}else{
				__errors[errorName]++;
			}
			
			
			var xml : XML = new XML ();
			var xmlString : String = "";
			
			/*
				report
					project
						api_token
					error
						hash_string ( error id )
					occurence
						name
						reporter "flash"
						description ( human description )
						backtrace
						properties
							<key>value</key>
						
			*/
			
			var props : String = "";
			
			// arguments go on top
			if( fm.arguments != null )
			{
				for each( var arg : * in fm.arguments )
				{
					if( arg != null )
					{
						var name : String = getQualifiedClassName( arg ).toString();
						name = name.replace("::","."); // replace :: from the namespace to avoid xml errors
						props+="<"+name+"><![CDATA["+ arg.toString() +"]]></"+name+">";
					}
				}
			}
			
			var sdk : String = "flash";
			// flash player capabilities go at the bottom
			var capabilities : Array = CapabilitiesGrabber.getCapabilities();
			for each( var capability  : Object in capabilities )
			{
				props+="<"+capability.name+">" + capability.value +"</"+capability.name+">";
				if( capability.name.toLowerCase() == "capabilities.sdk" )
				{
					sdk = capability.value;
				}
			}
			
			xmlString += "<report>";
			xmlString += "<project><api_token>"+fm.api+"</api_token></project>";
			xmlString += "<error><hash_string>"+fm.error.errorID+"</hash_string></error>";
			xmlString += "<occurence>";
			xmlString += "<name>"+errorName+"</name>";
			xmlString += "<description>"+fm.error.message+"</description>";
			xmlString += "<reporter>"+sdk+"</reporter>";
			xmlString += "<backtrace>"+ fm.error.getStackTrace() +"</backtrace>";
			xmlString += "<properties>"+ props +"</properties>";
			xmlString += "</occurence>";
			xmlString += "</report>";
			
			xml = new XML( xmlString );
			
			lastRequest = xml;
			
			if( __errors[errorName] > MAX_OCCURENCES_SENT_TO_SERVER_IN_ONE_SESSION )
			{
				lastResult = new XML("<result>\n\t<success>1</success>\n\t<occurencecount>"+__errors[errorName]+"</occurencecount>\n\t<senttoserver>0</senttoserver>\n</result>");
				if( __callback != null )
				{
					try
					{
						__callback.apply(null,[]);
					}
					catch( e : Error )
					{
						trace(e.message);
					}
				}
			}else{
				var header1:URLRequestHeader = new URLRequestHeader("Content-Type", "application/xml");
				// accept xml as response
				var header2:URLRequestHeader = new URLRequestHeader("Accept","application/xml");
				
				var request:URLRequest = new URLRequest( __url + "/reports.xml");
				request.requestHeaders.push(header1);
				request.requestHeaders.push(header2);
				var loader:URLLoader = new URLLoader();
				//loader.dataFormat = URLLoaderDataFormat.VARIABLES;
				request.data = xml;
				request.method = URLRequestMethod.POST;
				loader.addEventListener(Event.COMPLETE, handleComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.load(request);
			}
			
		}
		
		private function handleComplete(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			var xml : XML = new XML( loader.data );
			var success : Boolean = int( xml.success ) == 1;
			lastResult = xml;
			
			if( __callback != null )
			{
				try
				{
					__callback.apply(null,[]);
				}
				catch( e : Error )
				{
					trace(e.message);
				}
			}
		}
		
		private function onIOError(event:IOErrorEvent):void 
		{
			trace("Error loading URL.");
		}

		
		/**
		 * 
		 * @return read only property that reads out the current api key
		 * 
		 */
		public function get api () : String
		{
			return __api;
		}
		
		/**
		 * 
		 * @param apikey init an instance of failtale and pass your api-key
		 * 
		 */
		public function init( url : String, apikey : String ) : void
		{
			__url = url;
			__api = apikey;
		}
		
		/**
		 * 
		 * @return use getInstance() to get an instance of the Failtale class
		 * 
		 */
		public static function getInstance () : Failtale
		{
			if( __instance == null )
			{
				__instance = new Failtale( new Enforcer );
			}
			return __instance;
		}
	}
}

class Enforcer {}