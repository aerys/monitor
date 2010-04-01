package aerys.monitor
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;
	import flash.utils.setInterval;
	
	public class Monitor extends Sprite
	{
		public static const DEFAULT_UPDATE_RATE		: Number	= 1;

		private static const DEFAULT_PADDING		: uint		= 20;
		private static const DEFAULT_BACKGROUND		: uint		= 0x00000000;
		private static const DEFAULT_CHART_WIDTH	: uint		= 100;
		private static const DEFAULT_CHART_HEIGHT	: uint		= 50;

		private var _updateRate		: Number		= 0.;
		private var _intervalId		: int			= 0;
		
		private var _targets		: Dictionary	= new Dictionary();
		private var _xml			: XML			= <debugger />;
		private var _colors			: Object		= new Object();
		
		private var _scales			: Object		= new Object();
		private var _overflow		: Object		= new Object();
		private var _style			: StyleSheet	= new StyleSheet();
		private var _label			: TextField		= new TextField();
		private var _bitmapData		: BitmapData	= new BitmapData(DEFAULT_CHART_WIDTH,
																	 DEFAULT_CHART_HEIGHT,
																	 true,
																	 DEFAULT_BACKGROUND);
		private var _chart			: Bitmap		= new Bitmap(_bitmapData);
		
		public function get chartWidth() : int { return _bitmapData.width; }
		
		public function get chartHeight() : int { return _bitmapData.height; }
		
		public function set chartWidth(value : int) : void
		{
			setChartSize(value, _bitmapData.height);
		}
		
		public function set chartHeight(value : int) : void
		{
			setChartSize(_bitmapData.width, value);
		}
		
		/**
		 * Create a new Monitor object. 
		 * @param myUpdateRate The number of update per second the monitor will perform.
		 * 
		 */
		public function Monitor(myUpdateRate : Number = DEFAULT_UPDATE_RATE)
		{
			super();
			
			_updateRate = myUpdateRate;
			_intervalId = setInterval(update, 1000. / _updateRate);
			
			_style.setStyle("debugger", {fontSize:		"9px",
										 fontFamily:	"_sans",
										 leading:		"-2px"});
			
			_label.styleSheet = _style;
			_label.condenseWhite = true;
			
			addChild(_label);
			addChild(_chart);
		}
		
		public function setChartSize(myWidth : int, myHeight : int) : void
		{
			var bmp : BitmapData = new BitmapData(myWidth, myHeight, true, DEFAULT_BACKGROUND);
			
			bmp.copyPixels(_bitmapData,
						   new Rectangle(0, 0, myWidth, myHeight),
						   new Point(myWidth - _bitmapData.width,
						   			 myHeight - _bitmapData.height));
			
			_bitmapData = bmp;
			_chart.bitmapData = _bitmapData;
		}
		
		private function update() : void
		{
			if (!visible)
				return ;

			_bitmapData.scroll(1, 0);
			_bitmapData.fillRect(new Rectangle(0, 0, 1, _bitmapData.height),
								 DEFAULT_BACKGROUND);
			_bitmapData.lock();
			
			for (var target : Object in _targets)
			{
				var properties : Array = _targets[target];
				var numProperties : int	= properties.length;
				
				for (var i : int = 0; i < numProperties; ++i)
				{
					var property : String = properties[i];
					var value : Object = target[property];
					var scale : Number = _scales[property];

					_xml[property] = property + ": " + value.toString();
					
					if ((scale = _scales[property]) != 0.)
					{
						var n : Number = Number(value);
						var scaledValue : Number = scale * (_overflow[property] ? Math.abs(n) % (1. / scale) : n);
						
						_bitmapData.setPixel32(0,
											  (1. - scaledValue) * (_bitmapData.height - 1),
											  0xff000000 | _colors[property]);
					}
				}
			}
			
			_bitmapData.unlock();			
			_label.htmlText = _xml;
		}
		
		/**
		 * Watch a property of a specified object.
		 * 
		 * @param myTarget The object containing the property to watch.
		 * @param myProperty The name of the property to watch.
		 * @param myColor The color of the displayed label/chart.
		 * @param myScale The scale used to display the chart. Use "0" to disable the chart.
		 * @param myOverflow If true, the modulo operator is used to make
		 * sure the value can be drawn on the chart.
		 */
		public function watch(myTarget 		: Object,
						      myProperty	: String,
							  myColor		: int		= 0xffffff,
							  myScale		: Number	= 0.,
							  myOverflow	: Boolean	= false) : void
		{
			if (!_targets[myTarget])
				_targets[myTarget] = new Array();
			
			_targets[myTarget].push(myProperty);
			_xml[myProperty] = myProperty + ": " + myTarget[myProperty];

			_colors[myProperty] = myColor;
			_scales[myProperty] = myScale;
			_overflow[myProperty] = myOverflow;
			
			_style.setStyle(myProperty, {color: "#" + (myColor as Number).toString(16)});
			_label.htmlText = _xml;
			_chart.y = _label.textHeight + DEFAULT_PADDING;
			_label.autoSize = TextFieldAutoSize.LEFT;
		}
	}
}