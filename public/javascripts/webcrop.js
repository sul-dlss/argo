var WebCrop = function(imgData, autoSaver) {
  
  // basic configuration options for the webcrop tool
  var config = {
    cropRotateAreaLength: 700, 
    thumbImgWidth: 100, 
    autoSaveIntervalInMillisecs: 5000, 
    lockCropCoords: false,
    lockRotationAngle: false
  };
  
  var img, autoSaveTimerId;
  
  /* method to initialize webcrop and its elements */
  var init = function() {
    var length, thumbImgHeight, slide;
            
    if (typeof imgData === 'undefined') {
      return;
    }
    
    $('#crop-rotate-background').css({
      'height': config.cropRotateAreaLength + 'px',
      'width': config.cropRotateAreaLength + 'px'
    });
    
    length = imgData.length;
    
    for (var index = 0; index < length; index++) {               
               
      thumbImgHeight = util.getHeight(config.thumbImgWidth, imgData[index].origWidth, imgData[index].origHeight);
            
      slide = $('<li></li>', { 'class': 'slide' });
            
      $('<img>', {
        'id': 'wc-slide-img-' + index, 
        'height': thumbImgHeight + 'px',
        'src': getThumbnailImgSrc(index),
        'width': config.thumbImgWidth + 'px',
        'class': 'slide-img', 
        
        click: function() {
          var imgIndex = parseInt(this.id.replace(/^wc-slide-img-/, ''), 10);
          
          config.lockCropCoords ? storeCropCoords(imgIndex) : clearCropCoords();      
          config.lockRotationAngle ? storeRotationAngle(imgIndex) : clearRotationAngle();      
                                 
          clearSlideBackgrounds();          
          $(this).parent().addClass('slide-bg-selected');
               
          loadImg(imgIndex);          
          updateSidebarMetadata(imgIndex);
          updateNextPrevNavButtons(imgIndex, length);          
          
          $('#opacity-slider').slider('value', 1); // reset opacity slider to 1          
        }
      }).appendTo(slide);
      
      $('<br/>').appendTo(slide);

      // select checkbox for each slide
      $('<input>', {
        id: 'wc-slide-chkbox-' + index, type: 'checkbox', 'class': 'chk-box'
      }).appendTo(slide);                
      
      $('<img>', {
        'id': 'wc-has-crop-coords-' + index,
        'src': '/images/icon-crop-coords.png',
        'class': 'has-crop-coords',
        'style': 'visibility: ' + (hasCropCoords(index) ? 'visible' : 'hidden') + ';'
      }).appendTo(slide);

      $('<img>', {
        'id': 'wc-has-rotation-angle-' + index,
        'src': '/images/icon-rotation-angle.png',
        'class': 'has-rotation-angle',
        'style': 'visibility: ' + (hasRotationAngle(index) ? 'visible' : 'hidden') + ';'
      }).appendTo(slide);
      
      slide.appendTo($('#slide-show-list'));                  
    }
    
    setupSliders();
    setupRotationButtons();    
    setupMultiSelect();
    bindMouseEvents();
    
    autoSaveTimerId = setInterval(autoSave, config.autoSaveIntervalInMillisecs);
          
    $('#wc-slide-img-0').click();
  }


  /* (re)load images for crop and rotate actions */
  var loadImg = function(index) {    
    var imgAttrs = imgData[index];        
    var cropRotateImgSize, imgWidth, imgHeight;
    var canvas, x, y;
    
    x = y = 0;

    $('#img-container').html('');
    
    canvas = Raphael('img-container', config.cropRotateAreaLength, config.cropRotateAreaLength);

    cropRotateImgSize = util.getCropRotateImgSize(config.cropRotateAreaLength, imgAttrs.origWidth, imgAttrs.origHeight);
    
    imgWidth  = cropRotateImgSize[0]; 
    imgHeight = cropRotateImgSize[1]; 
    
    x = parseInt((config.cropRotateAreaLength - imgWidth) / 2, 10);
    y = parseInt((config.cropRotateAreaLength - imgHeight) / 2, 10);

    img = canvas.image(imgAttrs.fileSrc, x, y, imgWidth, imgHeight);
    
    imgData[index].cropRatioHeight = parseFloat((imgAttrs.origHeight / imgHeight ).toFixed(2));            
    imgData[index].cropRatioWidth  = parseFloat((imgAttrs.origWidth / imgWidth ).toFixed(2));            

    setupCrop(index);
    setupRotation(index);
    
    // disable this slide's checkbox, and enable others
    $('.chk-box').removeAttr('disabled');
    $('#wc-slide-chkbox-' + index).attr('disabled', true);

  };
  
  
  /* setup crop plugin for a given images and draw crop area if crop coords are available */
  var setupCrop = function(index) {
    var cropCoords, x1, y1, x2, y2, width, height;
    var imgAttrs = imgData[index];
        
    $('#img-container').imgAreaSelect({
      'instance': true, 
      'handles': true,
      'keys': true,
      'maxHeight': config.cropRotateImgSize,
      'maxWidth': config.cropRotateImgSize,
      'minHeight': 1,
      'minWidth': 1,      
      'onSelectChange': function(img, crop) {
        $('#x1-val').html(parseInt(crop.x1 * imgAttrs.cropRatioWidth, 10));
        $('#y1-val').html(parseInt(crop.y1 * imgAttrs.cropRatioHeight, 10));
        $('#x2-val').html(parseInt(crop.x2 * imgAttrs.cropRatioWidth, 10));
        $('#y2-val').html(parseInt(crop.y2 * imgAttrs.cropRatioHeight, 10));
  
        $('#width-val').html(parseInt(crop.width * imgAttrs.cropRatioWidth, 10));
        $('#height-val').html(parseInt(crop.height * imgAttrs.cropRatioHeight, 10));
      },
      'onSelectEnd': function(img, crop) {
        var index = getActiveImgIndex();
        storeCropCoords(index);
      }      
    });
    
    $('.imgareaselect-outer').click(function() {
      clearCropCoords();
    });
            
    if (hasCropCoords(index)) {
      cropCoords = imgAttrs.cropCoords;
            
      width  = cropCoords.x2 - cropCoords.x1;
      height = cropCoords.y2 - cropCoords.y1;
      
      showCropCoords([cropCoords.x1, cropCoords.y1, cropCoords.x2, cropCoords.y2, width, height]);

      // calculate crop coords relative to the displayed image size
      x1 = parseInt(cropCoords.x1 / imgAttrs.cropRatioWidth, 10);
      y1 = parseInt(cropCoords.y1 / imgAttrs.cropRatioHeight, 10);
      x2 = parseInt(cropCoords.x2 / imgAttrs.cropRatioWidth, 10);
      y2 = parseInt(cropCoords.y2 / imgAttrs.cropRatioHeight, 10);
      
      $('#img-container').imgAreaSelect({ 
        'x1': parseInt(x1, 10), 'y1': parseInt(y1, 10), 
        'x2': parseInt(x2, 10), 'y2': parseInt(y2, 10) 
      }); 
    } else {      
      if (!config.lockCropCoords) {
        $('#img-container').imgAreaSelect({ instance: true }).cancelSelection();
      }           
    }           
  };
  
  
  /* rotate image if rotation angle is available */
  var setupRotation = function(index) {
    var angle;
    var imgAttrs = imgData[index];
    
    clearRotationAngle();
    
    if (hasRotationAngle(index)) {
      rotateImg(imgAttrs.rotationAngle, true, false, false);
    }
  };
    
  
  /* get thumbnail image source */
  var getThumbnailImgSrc = function(index) {
    var thumbnailSrc = imgData[index].fileSrc;
    
    if (typeof imgData[index].thumbnailSrc !== 'undefined') {
      thumbnailSrc = imgData[index].thumbnailSrc;
    }
    
    return thumbnailSrc;
  };
  
  
  /* update metadata fields (filename, dimensions etc.) */
  var updateSidebarMetadata = function(index) {
    var dimensions = imgData[index].origWidth + ' x ' + imgData[index].origHeight + ' px';
    
    var fileName = "-";
    var regex = /id=(\w+)/i; // assuming id is a string with no spaces
    var match;
    
    if (typeof imgData[index].fileName !== 'undefined') {
      fileName = imgData[index].fileName; 
    } else {
      match = regex.exec(imgData[index].fileSrc); // get id value
      
      // display 'Id: ' label and id value (instead of file name)
      if (match != null && match[1] != null && match[1].length > 0) {
        fileName = match[1];
        $('#md-filename-label').html('Id: ');   
      }       
    }
         
    $('#md-filename').html(fileName);
    $('#md-dimensions').html(dimensions);
  };


  /* update sidebar image navigation button links */
  var updateNextPrevNavButtons = function(index, maxValue) {
    var nextIndex = index + 1;
    var prevIndex = index - 1;
    
    $('#btn-img-nav-prev').removeAttr('disabled');
    $('#btn-img-nav-next').removeAttr('disabled');        
    
    if (prevIndex < 0) {
      $('#btn-img-nav-prev').attr('disabled', true);
    } 

    if (nextIndex >= maxValue) {
      $('#btn-img-nav-next').attr('disabled', true);      
    }
  };

  
  /* check if given image has crop coordinates */
  var hasCropCoords = function(index) {
    var imgAttrs = imgData[index];
    var cropCoords;
    
    if (typeof imgAttrs !== 'undefined' && typeof imgAttrs.cropCoords !== 'undefined') {
      cropCoords = imgAttrs.cropCoords;
      
      if ('x1' in cropCoords && 'y1' in cropCoords && 'x2' in cropCoords && 'y2' in cropCoords) {
        return true;
      }
    }    
    
    return false;
  };  
  
  
  /* store currently cropped coordinates to image */
  var storeCropCoords = function(index) {
    var width  = parseInt($('#width-val').html(), 10);
    var height = parseInt($('#height-val').html(), 10);
    var props  = [ 'x1', 'y1', 'x2', 'y2' ];
    //var index = getActiveImgIndex();
        
    if (width > 0 && height > 0) {         
      
      if (typeof imgData[index].cropCoords === 'undefined') {
        imgData[index].cropCoords = {};
      } 
      
      // store values in the main hash
      $.each(props, function(i, key) {
        imgData[index].cropCoords[key] = parseInt($('#' + key + '-val').html(), 10);
      });
      
      $('#wc-has-crop-coords-' + index).css('visibility', 'visible');            
    }    
    // if crop size is 0 x 0, delete crop coords 
    else {
      delete imgData[index].cropCoords;
      clearCropCoords();
      
      $('#wc-has-crop-coords-' + index).css('visibility', 'hidden');                  
    }
    imgData[index].dirty = true;
  };

  /* clear crop coordinates from sidebar */
  var clearCropCoords = function() {
    var props = [ 'x1', 'y1', 'x2', 'y2', 'width', 'height' ];
    var index = getActiveImgIndex();

    $.each(props, function(i, key) {
      $('#' + key + '-val').html('');
    });
  }; 
  
  
  /* show crop coordinates in sidebat */
  var showCropCoords = function(values) {    
    var props = ['x1', 'y1', 'x2', 'y2', 'width', 'height'];
    
    if (typeof values !== 'undefined') {       
      $.each(props, function(i, key) {
        if (typeof values[i] !== 'undefined') {
          $('#' + key + '-val').html(values[i]);
        }    
      });
    }
  };

  /* check if given image has rotation angle */
  var hasRotationAngle = function(index) {
    var imgAttrs = imgData[index];
    
    if (typeof imgAttrs !== 'undefined' && 'rotationAngle' in imgAttrs && imgAttrs.rotationAngle > 0) {
      return true;      
    }
    
    return false;
  };

  
  /* store rotation angle in main hash */
  var storeRotationAngle = function(index) {
    var angle = util.clampAngle(parseInt($('#rotation-angle-slider').slider('value'), 10));
    
    imgData[index].rotationAngle = angle;
    
    if (angle > 0) {      
      $('#wc-has-rotation-angle-' + index).css('visibility', 'visible');                
    }
    imgData[index].dirty = true;
  };
  
  
  /* reset rotation angle slider and sidebar rotation angle value */
  var clearRotationAngle = function() {
    rotateImg(0, true, false);
    
    $('#rotation-angle-slider').slider('value', 0); // reset rotation slider to 0
    $('#rotation-angle').html('0');
  };
  
  
  /* setup opacity and rotation sliders */
  var setupSliders = function() {
    // image opacity slider
    $('#opacity-slider').slider({
      'from': 0.0, 
      'to': 1.0,
      'step': 0.1, 
      'scale': [0.0, '|', '|', '|', '|', 0.5, '|', '|', '|', '|', 1.0],
      'limits': false, 
      'round': 1,
      'skin': 'plastic',
      'calculate': function(value) {        
        value = value.toString().replace(/,/, '.');
        
        if (typeof img !== 'undefined') {
          img.attr('opacity', parseFloat(value));
        }
        
        return value; 
      }
    });    

    // rotation angle slider
    $('#rotation-angle-slider').slider({
      'from': 0, 
      'to': 360,
      'step': 1, 
      'scale': ['0&deg;', '|', '90&deg;', '|', '180&deg;', '|', '270&deg;', '|', '360&deg;'],
      'limits': false, 
      'round': 1,
      'skin': 'plastic',
      'dimension': '&deg;', 
      'calculate': function(value) {
        value = value.toString().replace(/,/, '.');

        if (typeof img !== 'undefined') {                    
          rotateImg(value, true, true, true);
          $('#rotation-angle').html(value);
        }
        
        return value;
       }
    });    
  };
  
  
  /* setup rotation buttons - 90 deg cw, ccw & 1 deg cw, ccw */
  var setupRotationButtons = function() {
    $('#btn-rotate-90-cw').click(function() { rotateImg(90.0, false, false, true); });
    $('#btn-rotate-90-ccw').click(function() { rotateImg(-90.0, false, false, true); });

    $('#btn-rotate-pt1-cw').click(function() { rotateImg(1, false, false, true); });
    $('#btn-rotate-pt1-ccw').click(function() { rotateImg(-1, false, false, true); });
  };  
  

  /* rotate image to a given angle */  
  var rotateImg = function(angle, isAbsolute, isSliderCallback, storeAngle) {
    var sliderValue;
    var index = getActiveImgIndex();
    
    if (typeof img === 'undefined') {
      return;
    }

    if (typeof isSliderCallback === 'undefined') {
      isSliderCallback = false;
    }

    if (typeof storeAngle === 'undefined') {
      isSliderCallback = true;
    }
        
    sliderValue = parseInt($('#rotation-angle-slider').slider('value'), 10); 
    angle = util.clampAngle(angle);

    img.rotate(angle, isAbsolute);
    
    if (angle > 0 && storeAngle) {      
      storeRotationAngle(index);
    }
    
    if (!isSliderCallback) {      
      sliderValue += angle;
      $('#rotation-angle-slider').slider('value', util.clampAngle(sliderValue));
    }     
  };
  
  
  /* clear slide's 'selected' background */
  var clearSlideBackgrounds = function() {
    $('.slide').each(function() {
      $(this).removeClass('slide-bg-selected');
    });
  };  
  

  /* get current, active image index */
  var getActiveImgIndex = function() {
    var currentImgId, index = 0;        
    
    currentImgId = $('.slide.slide-bg-selected > .slide-img').attr('id');
    
    if (typeof currentImgId !== 'undefined') {      
      index = parseInt(currentImgId.replace(/^wc-slide-img-/, ''), 10);
    }

    return index;    
  };  


  /* set up multi-select dropdown actions */
  var setupMultiSelect = function() {
    var selection;
    
    $('#multi-select-dropdown').change(function() {
      var index = getActiveImgIndex();
      var selection = $('#multi-select-dropdown').val();      
          
      switch(selection) {        
        case "SelectAll":          
          $('.chk-box').each(function() {
            $(this).attr('checked', 'checked');
            
            if (hasCropCoords(index)) { $('#btn-apply-crop').attr('disabled', false); }
            if (hasRotationAngle(index)) { $('#btn-apply-rotation').attr('disabled', false); }
          });    
          break;
        
        case "UnSelectAll":
          unSelectAllSlides();
          break;
        
        case "SelectOddPages":
          var i = 0;
          
          $('.chk-box').each(function() {
            $(this).removeAttr('checked');
            
            if ((++i % 2) == 1) {
              $(this).attr('checked', 'checked');
            }
            
            if (hasCropCoords(index)) { $('#btn-apply-crop').attr('disabled', false); }
            if (hasRotationAngle(index)) { $('#btn-apply-rotation').attr('disabled', false); }
          });    

        case "SelectEvenPages":
          var i = 0;
          
          $('.chk-box').each(function() {
            $(this).removeAttr('checked');
            
            if ((++i % 2) == 0) {
              $(this).attr('checked', 'checked');
            }
            
            if (hasCropCoords(index)) { $('#btn-apply-crop').attr('disabled', false); }
            if (hasRotationAngle(index)) { $('#btn-apply-rotation').attr('disabled', false); }
          });    
          
        default:        
      }      
    });
  };

  /* unselect all slides */
  var unSelectAllSlides = function() {
    $('.chk-box').each(function() {
      $(this).removeAttr('checked');
      $('#btn-apply-crop').attr('disabled', true);      
      $('#btn-apply-rotation').attr('disabled', true);      
    });        
    
    $('#multi-select-dropdown').val("");
  };

  /* bind mouse events on init() */
  var bindMouseEvents = function() {
    
    // setup previous nav button 
    $('#btn-img-nav-prev').click(function() {
      var prevIndex = getActiveImgIndex() - 1;
      $('#wc-slide-img-' + prevIndex).click();
    });
  
    // setup next nav button 
    $('#btn-img-nav-next').click(function() {
      var nextIndex = getActiveImgIndex() + 1;
      $('#wc-slide-img-' + nextIndex).click();
    });
  
    // apply crop attributes across selection
    $('#btn-apply-crop').click(function() {
      var index = getActiveImgIndex();
      
      if (hasCropCoords(index)) {
        $('.chk-box').each(function(){
          if ($(this).is(':checked')) {
            var chkboxIndex = $(this).attr('id').replace(/^wc-slide-chkbox-/, '');            
            storeCropCoords(chkboxIndex);
          }
        });
      }
            
      unSelectAllSlides();    
    });  
        
    // apply rotation angle across selection
    $('#btn-apply-rotation').click(function() {
      var index = getActiveImgIndex();
      
      if (hasRotationAngle(index)) {
        $('.chk-box').each(function(){
          if ($(this).is(':checked')) {
            var chkboxIndex = $(this).attr('id').replace(/^wc-slide-chkbox-/, '');            
            storeRotationAngle(chkboxIndex);
          }
        });
      }
      
      unSelectAllSlides();    
    });  

        
    // enable/disable 'Apply crop attributes' & 'Apply rotation angle' buttons
    $('.chk-box').change(function() {
      var index = getActiveImgIndex();
  
      $('#btn-apply-crop').attr('disabled', true);
      $('#btn-apply-rotation').attr('disabled', true);
      
      $('.chk-box').each(function() {
        if ($(this).is(':checked')) {
          if (hasCropCoords(index)) { $('#btn-apply-crop').attr('disabled', false); }
          if (hasRotationAngle(index)) { $('#btn-apply-rotation').attr('disabled', false); }
        }
      });    
    });
        
    // setup shift click for slide-show checkboxes
    $('input.chk-box').shiftClick();      
    
    // setup lock crop coordinates toggle
    $('#lock-crop-coords').click(function() {
      if (config.lockCropCoords) {
        config.lockCropCoords = false;
        $('#lock-crop-coords').attr('src', '/images/icon-lock-disabled.png');
      } else {
        config.lockCropCoords = true;
        $('#lock-crop-coords').attr('src', '/images/icon-lock-enabled.png');      
      }
    });    

    // setup lock crop coordinates toggle
    $('#lock-rotation-angle').click(function() {
      if (config.lockRotationAngle) {
        config.lockRotationAngle = false;
        $('#lock-rotation-angle').attr('src', '/images/icon-lock-disabled.png');
      } else {
        config.lockRotationAngle = true;
        $('#lock-rotation-angle').attr('src', '/images/icon-lock-enabled.png');
      }
    });    
  };


  /* auto save method that runs forever (triggered by the setInterval function at the top) */
  var autoSave = function() {
    // imgData is the main JavaScript hash    
    // To convert imgData has to string - 
    // var str = JSON.stringify(imgData, null);
    
    if (autoSaver != null) {
      autoSaver(imgData);
    }
    
    /*
    $.ajax({
      url: "url.html",
      context: document.body,
      success: function(){
        var formattedDate = $.format.date((new Date()).toString(), 'MM/dd/yyyy hh:mm:ss a');    
        $('#last-saved .date-value').html(formattedDate);        
      }
    });     
    */
  };

  
  /* utility methods - get proportional height, width etc. */
  var util = {
    
    // get height for a given width (maintaing aspect ratio)
    getHeight: function(width, origWidth, origHeight) {
      var height = parseInt((origHeight / origWidth) * width, 10);
      return height;
    },
      
    // get width for a given height (maintaing aspect ratio)
    getWidth: function(height, origWidth, origHeight) {
      var width = parseInt((origWidth / origHeight) * height, 10);
      return width;
    },
    
    // calculate & store dimensions for the img to be placed in crop-rotate area 
    getCropRotateImgSize: function(cropRotateAreaSide, origWidth, origHeight) {
      var aspectRatio, height, width;      
      
      aspectRatio = (origWidth / origHeight).toFixed(2);
      
      /* 
        1. aspectRatio = width/height
        2. width^2 + height^2 = cropRotateAreaSide^2
        
        solving above two equations, we get, 
          height = sqrt[(cropRotateAreaSide^2) / (aspectRatio^2 + 1)]
          width  = aspectRatio * height       
      */
      height = parseInt(Math.sqrt(Math.pow(cropRotateAreaSide, 2) / (Math.pow(aspectRatio, 2) + 1.0)), 10);
      width  = parseInt((aspectRatio * height), 10);

      return [width, height];                   
    },
    
    // clamp a given angle between 0 and 360 degrees
    clampAngle: function(angle) {
      if (parseFloat(angle) < 0.0) { angle = parseFloat(angle) + 360.0; }
      if (parseFloat(angle) >= 360.0) { angle = parseFloat(angle) - 360.0; }
      
      return angle;      
    }
  };
    
  // run
  init();
};
