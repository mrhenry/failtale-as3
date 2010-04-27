# Failtale AS3

This AS3 library integrates seamlessly with the Failtale app ([homepage][home], [GitHub][github] ). Include the SWC file from the bin folder into your app, initialize Failtale with your API key and you're ready to roll.

## Example Usage:

A more complete example is available [here](http://github.com/webdevotion/Failtale-AS3-Example-Application)

    // create your own API key on www.failtale.be
    public static const FAILTALE_API_KEY : String = "your-api-key-goes-here";
    private var failtale : Failtale;
    
    private function initFailtale () : void
    {
      failtale = Failtale.getInstance();
      failtale.init( FAILTALE_API_KEY );
    }
    
    // what follows is a poor example probably
    // you shouldn't track every single error or become a lazy coder
    private function triggerError ( e : Event ) : void
    {
      // try to remove a dummy instance from the displaylist
      try
      {
        removeChild( dummy );
      }
      catch( error : Error )
      {
        // removing dummy failed ( e.g. it was not added to the displaylist )
        // let Failtale know about it
        var fm : FailtaleModel = new FailtaleModel();
        fm.comment = commentInput.text;
        fm.error = error;
        fm.arguments = arguments;
        failtale.log( fm );
      }
    }

-- Failtale  
Tells you more about failing applications

  [home]: www.failtale.be
  [github]: http://github.com/mrhenry/failtale