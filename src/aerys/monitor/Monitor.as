package aerys.monitor
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public class Monitor extends Sprite
	{
		//{ region static
		public static const DEFAULT_UPDATE_RATE		: Number	= 1;

		private static const DEFAULT_PADDING		: uint		= 10;
		private static const DEFAULT_BACKGROUND		: uint		= 0x7f000000;
		private static const DEFAULT_CHART_WIDTH	: uint		= 100;
		private static const DEFAULT_CHART_HEIGHT	: uint		= 50;
		
		private static const DEFAULT_COLOR			: uint		= 0xffffffff;

		private static var _instance : Monitor		= null;
		public static function get monitor() : Monitor
		{
			return _instance || (_instance = new Monitor());
		}
		//} endregion
		
		private var _defaultColor	: uint			= DEFAULT_COLOR;
		
		private var _updateRate		: Number		= 0.;
		private var _intervalId		: int			= 0;
		
		private var _targets		: Dictionary	= new Dictionary();
		private var _xml			: XML			= <monitor>
														<version />
														<framerate>framerate:</framerate>
														<memory>memory:</memory>
													  </monitor>;
		private var _colors			: Object		= new Object();
		
		private var _scales			: Object		= new Object();
		private var _overflow		: Object		= new Object();
		private var _style			: StyleSheet	= new StyleSheet();
		private var _label			: TextField		= new TextField();
		private var _bitmapData		: BitmapData	= new BitmapData(DEFAULT_CHART_WIDTH,
																	 DEFAULT_CHART_HEIGHT,
																	 true,
																	 0);
		private var _chart			: Bitmap		= new Bitmap(_bitmapData);
		
		private var _numFrames		: int			= 0;
		private var _updateTime		: int			= 0;
		private var _framerate		: int			= 0;
		private var _maxMemory		: int			= 0;
		
		private var _background		: uint			= 0;
		
		public function get defaultColor() : uint { return _defaultColor; }
		
		public function get framerate() : int	{ return _framerate; }
		
		public function get chartWidth() : int { return _bitmapData.width; }
		
		public function get chartHeight() : int { return _bitmapData.height; }
	
		public function set defaultColor(value : uint) : void
		{
			_defaultColor = value;
		}
		
		public function set chartWidth(value : int) : void
		{
			setChartSize(value, _bitmapData.height);
		}
		
		public function set chartHeight(value : int) : void
		{
			setChartSize(_bitmapData.width, value);
		}
		
		public function set updateRate(value : Number) : void
		{
			_updateRate = value;
		}
		
		public function get updateRate() : Number
		{
			return _updateRate;
		}
		
		public function set backgroundColor(value : uint) : void
		{
			_background = value;
			updateBackground();
		}
		
		public function get backgroundColor() : uint
		{
			return _background;
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
			
			_style.setStyle("monitor", {fontSize:	"9px",
										fontFamily:	"_sans",
										leading:	"-2px"});
			
			setStyle("framerate", {color: "#ffaa00"});
			setStyle("memory", {color: "#0066ff"});
			setStyle("version", {color: "#7f7f7f"});
			
			_label.styleSheet = _style;
			_label.condenseWhite = true;
			_label.autoSize = TextFieldAutoSize.LEFT;
			
			addChild(_label);
			addChild(_chart);
			
			_xml.version = Capabilities.version + (Capabilities.isDebugger ? " (debug)" : "")
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			//addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			
			_background = DEFAULT_BACKGROUND;
		}
		
		public function setChartSize(width : int, height : int) : void
		{
			var bmp : BitmapData = new BitmapData(width, height, true, 0);
			
			bmp.copyPixels(_bitmapData,
						   new Rectangle(0, 0, width, height),
						   new Point(width - _bitmapData.width,
							   		 height - _bitmapData.height));
			
			_bitmapData = bmp;
			_chart.bitmapData = _bitmapData;
		}
		
		public function setStyle(styleName : String, value : Object) : void
		{
			_style.setStyle(styleName, value);
			
			if (value.color)
				_colors[styleName] = 0xff000000 | parseInt(value.color.substr(1), 16);
		}
		
		private function enterFrameHandler(event : Event) : void
		{
			++_numFrames;
			
			var time : int = getTimer();
			
			if ((time - _updateTime) >= 1000. / _updateRate)
			{
				// framerate
				_framerate = _numFrames / ((time - _updateTime) / 1000.);

				if (!visible || !stage)
				{
					_updateTime = time;
					_numFrames = 0;
					
					return ;
				}
				
				// prepare bitmap data
				_bitmapData.scroll(1, 0);
				_bitmapData.fillRect(new Rectangle(0, 0, 1, _bitmapData.height),
									 0);
				_bitmapData.lock();


				_xml.framerate = "framerate: " + _framerate + " / " + stage.frameRate;
				_bitmapData.setPixel32(0,
									   (1. - _framerate / stage.frameRate) * (_bitmapData.height - 1),
									   0xff000000 | _colors["framerate"])
					
				// memory
				var totalMemory : int = System.totalMemory;
				
				if (totalMemory > _maxMemory)
					_maxMemory = totalMemory;
				
				_xml.memory = "memory: " + (totalMemory / 1e6).toFixed(3) + " M.";
				_bitmapData.setPixel32(0,
									  (1. - totalMemory / _maxMemory) * (_bitmapData.height - 1),
									  0xff000000 | _colors["memory"])
				
				// properties
				for (var target : Object in _targets)
				{
					var properties : Array = _targets[target];
					var numProperties : int	= properties.length;
					
					for (var i : int = 0; i < numProperties; ++i)
					{
						var property : String = properties[i];
						var value : Object = target[property];
						var scale : Number = _scales[property];
	
						_xml[property] = property + ": " + value;
						
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
				
				_numFrames = 0;
				_updateTime = time;
				
				updateBackground();
			}
			
			_chart.y = _label.textHeight + DEFAULT_PADDING;
		}
		
		private function addedToStageHandler(e : Event) : void
		{
			_maxMemory = System.totalMemory;
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function removedFromStageHandler(e : Event) : void
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		public function setColor(property : String, color : int) : void
		{
			_colors[property] = color;
		}
		
		public function getColor(property : String) : int
		{
			return _colors[property];
		}
		
		public function getScale(property : String) : Number
		{
			return _scales[property];
		}
		
		public function setScale(property : String, scale : Number) : void
		{
			_scales[property] = scale;
		}
		
		public function getOverflow(property : String) : Boolean
		{
			return _overflow[property];
		}
		
		public function setOverflow(property : String, overflow : Boolean) : void
		{
			_overflow[property] = overflow;
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
		public function watchProperty(target	: Object,
								      property	: String,
									  color		: int		= 0,
									  scale		: Number	= 0.,
									  overflow	: Boolean	= false) : Monitor
		{
			if (!_targets[target])
				_targets[target] = new Array();
			
			color ||= _defaultColor;
			
			_targets[target].push(property);
			_xml[property] = property + ": " + target[property];

			_colors[property] = color;
			_scales[property] = scale;
			_overflow[property] = overflow;
			
			_style.setStyle(property, {color: "#" + (color as Number & 0xffffff).toString(16)});
			_label.htmlText = _xml;
			_chart.y = _label.textHeight + DEFAULT_PADDING;
			_label.autoSize = TextFieldAutoSize.LEFT;
			
			updateBackground();
			
			return this;
		}
		
		public function watch(target 		: Object,
							  properties	: Array,
							  colors		: Array		= null,
							  scales		: Array		= null,
							  overflows		: Array		= null) : Monitor
		{
			var numProperties : int = properties.length;
			
			for (var i : int = 0; i < numProperties; ++i)
			{
				watchProperty(target,
					  properties[i],
					  colors ? colors[i] : _defaultColor,
					  scales && scales[i] ? scales[i] : 0.,
					  overflows ? overflows[i] : false);
			}
			
			return this;
		}
		
		public function watchObject(target : Object) : Monitor
		{
			for (var property : String in target)
				watchProperty(target, property);
			
			return this;
		}
		
		private function updateBackground() : void
		{
			if (_label.textWidth == width && _label.textHeight == height)
				return ;
			
			graphics.clear();
			graphics.beginFill(_background & 0xffffff, ((_background >> 24) & 0xff) / 255.);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
		}
	}
}