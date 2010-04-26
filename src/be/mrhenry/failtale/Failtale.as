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
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;

	/**
	 * 
	 * @author Bram Plessers
	 * 
	 */
	public class Failtale
	{
		/**
		 * @private
		 * your api-key: get one from www.failtale.be
		 */
		private var __api : String = "get your API key from www.failtale.be";
		
		/**
		 * @private keeps track of the singleton instance
		 */
		private static var __instance : Failtale;
		
		
		
		/**
		 * 
		 * @param e initialize a Failtale instance using Failtale.getInstance()
		 * 
		 */
		public function Failtale( e : Enforcer )
		{
			
		}
		
		public function log( failtaleModel : FailtaleModel ) : void
		{
			failtaleModel.api = __api;
			
			
			var fm : FailtaleModel = failtaleModel;
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
			var capabilities : Array = CapabilitiesGrabber.getCapabilities();
			for each( var capability  : Object in capabilities )
			{
				props+="<"+capability.name+">" + capability.value +"</"+capability.name+">";
			}

			if( fm.arguments != null )
			{
				for each( var arg : * in fm.arguments )
				{
					var name : String = getQualifiedClassName( arg ).toString();
					name = name.replace("::","."); // replace :: from the namespace to avoid xml errors
					props+="<"+name+"><![CDATA["+ arg.toString() +"]]></"+name+">";
				}
			}
			
			var errorName : String = fm.error.name; // should define a better way to get a more descriptive name
			trace(errorName);
			xmlString += "<report>";
			xmlString += "<project><api_token>"+fm.api+"</api_token></project>";
			xmlString += "<error><hash_string>Error ID "+fm.error.errorID + ": " + fm.error.name+"</hash_string></error>";
			xmlString += "<occurence>";
			xmlString += "<name>"+errorName+"</name>";
			xmlString += "<description>"+fm.error.message+"</description>";
			xmlString += "<reporter>flash</reporter>";
			xmlString += "<backtrace>"+ fm.error.getStackTrace() +"</backtrace>";
			xmlString += "<properties>"+ props +"</properties>";
			xmlString += "</occurence>";
			xmlString += "</report>";
			
			xml = new XML( xmlString );
			
			var header1:URLRequestHeader = new URLRequestHeader("Content-Type", "application/xml");
			// accept xml as response
			var header2:URLRequestHeader = new URLRequestHeader("Accept","application/xml");
			
			var request:URLRequest = new URLRequest("http://0.0.0.0:3000/reports.xml");
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
		
		private function handleComplete(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			var xml : XML = new XML( loader.data );
			var success : Boolean = int( xml.success ) == 1;
			
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
		public function init( apikey : String ) : void
		{
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