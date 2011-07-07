$(document).ready(function() {
  var cropImgWidth = 475;
  var rotateImgWidth = 350;
  var thumbImgWidth = 100;
  var currentCropRatio;
  var apiJcrop;
  
  var config = {
    lockCropCoords: false,
    lockCropSize: false,
    jCropOpacity: 0.4    
  }
  
  if(imgData !== undefined && imgData.length > 0) {    
    setJcrop();
    setCropRatios();
    
    for (var i = 0; i < imgData.length; i++) {      
      var thumbImgHeight = getHeight(thumbImgWidth, imgData[i].origWidth, imgData[i].origHeight);
      var visibility = hasCropCoords(i) ? 'visible' : 'hidden';      
      
      var slide = $('<li></li>', { 'class': 'slide' });
            
      $('<img>', {
        id: 'img_' + i, 
        height: thumbImgHeight + 'px',
        src: imgData[i].fileSrc,
        width: thumbImgWidth + 'px',
        'class': 'slide-img', 
        click: function() {
          var index = parseInt($(this).attr('id').replace(/^img_/, ''), 10);
          
          config.lockCropCoords ? storeCropAttrs(index) : clearCropAttrs();                             
          loadImgs(cropImgWidth, rotateImgWidth, index);
          updateMetadata(index);
          updateNavButtons(index, imgData.length);
          
          clearSlideBackgrounds();
          $(this).parent().addClass('slide-bg-selected');     
        }
      }).appendTo(slide);
      
      $('<br/>').appendTo(slide);

      $('<input>', {
        id: 'chkbox_' + i, type: 'checkbox', 'class': 'chk-box'
      }).appendTo(slide);                
      
      $('<img>', {
        id: 'has_crop_coords_' + i,
        src: pathTo('/images/icons/icon-crop-coords.png'),
        'class': 'has-crop-coords',
        style: 'visibility: ' + visibility
      }).appendTo(slide);
      
      slide.appendTo($('#slide-show-list'));            
    }
    
    // load the first image
    $('#img_0').click();
  }  
  
  
  // (re)load images for crop and rotate actions
  function loadImgs(cropImgWidth, rotateImgWidth, index) {    
    var imgAttrs = imgData[index];
    
    $('#crop-img')
    .css({ 
      height: getHeight(cropImgWidth, imgAttrs.origWidth, imgAttrs.origHeight) + 'px', 
      width: cropImgWidth + 'px' 
    })
    .attr('src', imgAttrs.fileSrc);

    // remove existing image element 
    $('#rotate-img').remove();

    // create new image element for rotate action and attach it    
    $('<img>', {
      id: 'rotate-img',
      src: imgAttrs.fileSrc, 
      css: { 
        height: getHeight(rotateImgWidth, imgAttrs.origWidth, imgAttrs.origHeight) + 'px', 
        width: rotateImgWidth + 'px' 
      }
    }).appendTo('#rotate-container');    
    
    // disable this slide's checkbox
    $('.chk-box').removeAttr('disabled');
    $('#chkbox_' + index).attr('disabled', true);
    
    // initialize crop and rotation actions
    apiJcrop.destroy();
    setJcrop(index);  
    $('#rotate-img').rotate(0);
    currentCropRatio = imgAttrs.cropRatio;
  }


  // set Jcrop and crop coordinates (if available)
  function setJcrop(index) {
    var imgAttrs = imgData[index];
            
    apiJcrop = $.Jcrop('#crop-img', {
      bgOpacity: config.jCropOpacity,
      //onChange: showCoords, 
      onSelect: showCoords
    });
    
    if (hasCropCoords(index)) {
      var cropCoords = imgAttrs.cropCoords;

      var x1 = parseInt(cropCoords.x1 / imgAttrs.cropRatio, 10);
      var y1 = parseInt(cropCoords.y1 / imgAttrs.cropRatio, 10);
      var x2 = parseInt(cropCoords.x2 / imgAttrs.cropRatio, 10);
      var y2 = parseInt(cropCoords.y2 / imgAttrs.cropRatio, 10);

      $('#x1-val').val(cropCoords.x1),
      $('#y1-val').val(cropCoords.y1),
      $('#x2-val').val(cropCoords.x2),
      $('#y2-val').val(cropCoords.y2),
      $('#width-val').val(cropCoords.x2 - cropCoords.x1);
      $('#height-val').val(cropCoords.y2 - cropCoords.y1);
      
      apiJcrop.setSelect([ x1, y1, x2, y2 ]);
      apiJcrop.enable();      
    }
  }
  
  // check if this image has crop coordinates
  function hasCropCoords(index) {
    var imgAttrs = imgData[index];
    
    if (typeof imgAttrs != 'undefined' && typeof imgAttrs.cropCoords != 'undefined') {
      var cropCoords = imgAttrs.cropCoords;
      
      if ('x1' in cropCoords && 'y1' in cropCoords && 'x2' in cropCoords && 'y2' in cropCoords) {
        return true;
      }
    }    
    
    return false;
  }
  
  // store currently cropped coordinates
  function storeCropAttrs(index) {
    var width = parseInt($('#width-val').val(), 10);
    var height = parseInt($('#height-val').val(), 10);
        
    if (width > 0 && height > 0) {   
      if (typeof imgData[index].cropCoords === 'undefined') {
        imgData[index].cropCoords = {};
      } 
        
      imgData[index].cropCoords.x1 = $('#x1-val').val();      
      imgData[index].cropCoords.y1 = $('#y1-val').val();      
      imgData[index].cropCoords.x2 = $('#x2-val').val();      
      imgData[index].cropCoords.y2 = $('#y2-val').val();
      
      $('#has_crop_coords_' + index).css('visibility', 'visible');            
    }
    
    // if crop size is 0 x 0, delete crop coords 
    if (height == 0 && width == 0) {
      delete imgData[index].cropCoords;
      clearCropAttrs();
      $('#has_crop_coords_' + index).css('visibility', 'hidden');                  
    }
  }

  // clear crop coordinates
  function clearCropAttrs() {
    $('#x1-val').attr('value', '');
    $('#y1-val').attr('value', '');
    $('#x2-val').attr('value', '');
    $('#y2-val').attr('value', '');
    $('#width-val').attr('value', '');
    $('#height-val').attr('value', '');
  }
  

  // calculate and store crop ratios for all images
  function setCropRatios() {
    if (imgData === undefined || imgData.length <= 0) return;
    
    for (var i = 0; i < imgData.length; i++) {
      imgData[i].cropRatio = parseFloat((imgData[i].origWidth / cropImgWidth).toFixed(2));
    }
  }
  
  
  // show crop co-ordinates
  function showCoords(crop) {    
    if (typeof currentCropRatio === 'undefined') {
      currentCropRatio = 1;
    }
    
    $('#x1-val').val(parseInt(crop.x * currentCropRatio, 10));
    $('#y1-val').val(parseInt(crop.y * currentCropRatio, 10));
    $('#x2-val').val(parseInt(crop.x2 * currentCropRatio, 10));
    $('#y2-val').val(parseInt(crop.y2 * currentCropRatio, 10));
    $('#width-val').val(parseInt(crop.w * currentCropRatio, 10));
    $('#height-val').val(parseInt(crop.h * currentCropRatio, 10));
    
    storeCropAttrs(getActiveImgIndex());
  }
  
  // get current, active image index
  function getActiveImgIndex() {
    var currentImgId = $('.slide.slide-bg-selected > .slide-img').attr('id');
    var index = parseInt(currentImgId.replace(/^img_/, ''), 10);

    return index;    
  }
  
  // update metadata fields (filename, dimensions etc.)
  function updateMetadata(index) {
    var filename = imgData[index].fileSrc.replace(/^.*\//, '');
    var dimensions = imgData[index].origWidth + ' x ' + imgData[index].origHeight + ' px'; 
    
    $('#md-filename').html(filename);
    $('#md-dimensions').html(dimensions);
  }
  
  
  // update image navigation button links
  function updateNavButtons(index, maxValue) {
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
  }
  
	// setup previous nav button 
  $('#btn-img-nav-prev').click(function() {
		var prevIndex = getActiveImgIndex() - 1;
    $('#img_' + prevIndex).click();
  });

	// setup next nav button 
  $('#btn-img-nav-next').click(function() {
		var nextIndex = getActiveImgIndex() + 1;
    $('#img_' + nextIndex).click();
  });

  // apply crop attributes across selection
  $('#btn-apply-crop').click(function() {
    var index = getActiveImgIndex();
    
    if (hasCropCoords(index)) {
      $('.chk-box').each(function(){
        if ($(this).is(':checked')) {
          var chkboxIndex = $(this).attr('id').replace(/^chkbox_/, '');
          storeCropAttrs(chkboxIndex); 
        }
      });
    }
    
    $('#unselect-all-chkboxes').click();    
  });
  
  // enable/disable 'Apply crop attributes' button
  $('.chk-box').change(function() {
    var index = getActiveImgIndex();

    $('#btn-apply-crop').attr('disabled', true);
    
    $('.chk-box').each(function() {
      if ($(this).is(':checked') && hasCropCoords(index)) {
        $('#btn-apply-crop').attr('disabled', false);      
      }
    });    
  });
  
  // select all checkboxes
  $('#select-all-chkboxes').click(function() {
    var index = getActiveImgIndex();
    
    $('.chk-box').each(function() {
      $(this).attr('checked', 'checked');
      if (hasCropCoords(index)) {
        $('#btn-apply-crop').attr('disabled', false);      
      }
    });    
  });
  
  // unselect all checkboxes
  $('#unselect-all-chkboxes').click(function() {
    $('.chk-box').each(function() {
      $(this).removeAttr('checked');
      $('#btn-apply-crop').attr('disabled', true);      
    });    
  });
  
  // setup shift click for slide-show checkboxes
  $('input.chk-box').shiftClick();  
    
  // setup lock crop coordinates toggle
  $('#lock-crop-coords').click(function() {
    if (config.lockCropCoords) {
      config.lockCropCoords = false;
      $('#lock-crop-coords').attr('src', 'images/icon-lock-disabled.png');
    } else {
      config.lockCropCoords = true;
      $('#lock-crop-coords').attr('src', 'images/icon-lock-enabled.png');      
    }
  });


  // setup rotate slider
  $("#slider").slider({
    min: -90, max: 90, value: 0, 
    slide: function(event, ui) {
      $('#rotation-angle').val(ui.value);
      $('#rotate-img').rotate({
        angle: ui.value,
      });        
    }
  });


  // initial rotation value
  $('#rotation-angle').val($('#slider').slider('value'));


  // bind click event to 'crop' mode
  $('#mode-crop').click(function() {
    $('#mode-rotate').removeClass('mode-on').addClass('mode-off');  
    $('#mode-crop').removeClass('mode-off').addClass('mode-on');  
    $('#rotate-container').hide();
    disableRotationControls();  
    enableCropControls();  
    $('#crop-container').show();  
  }).click();  


  // bind click event to 'rotate' mode
  $('#mode-rotate').click(function() {
    $('#mode-crop').removeClass('mode-on').addClass('mode-off');  
    $('#mode-rotate').removeClass('mode-off').addClass('mode-on');
    $('#crop-container').hide();  
    $('#rotate-container').show();
    disableCropControls();      
    enableRotationControls();  
  });

  
  // bind event listener for rotation angle text box
  $('#rotation-angle').keyup(function(event) {
    var code = (event.keyCode ? event.keyCode : event.which);
    var angle = parseInt($('#rotation-angle').val(), 10);
    
    // if 'Enter' keycode is pressed 
    if(code == 13 && angle >= -90 && angle <= 90) {
      $('#rotate-img').rotate(angle);
      $('#slider').slider('value', angle); 
    }
  });      

  function clearSlideBackgrounds() {
    $('.slide').each(function() {
      $(this).removeClass('slide-bg-selected');
    });
  }
  
  // enable rotation controls
  function enableRotationControls(bool) {
    if (bool == undefined) {
      bool = true;
    }
    
    if (bool) {
      $('#rotation-angle').removeAttr('disabled');
      $('#slider').slider('option', 'disabled', false);    
    } else {
      $('#slider').slider('option', 'disabled', true);
      $('#rotation-angle').attr('disabled', true);    
    } 
  }
  
  // disable rotation controls
  function disableRotationControls() {
    enableRotationControls(false);
  }
  
  // enable crop controls
  function enableCropControls(bool) {
    if (bool == undefined) {
      bool = true;
    }
  
    if (bool) {
      $('#x1-val,#y1-val,#x2-val,#y2-val,#width-val,#height-val').removeAttr('disabled');
    } else {
      $('#x1-val,#y1-val,#x2-val,#y2-val,#width-val,#height-val').attr('disabled', true);
    } 
  }
  
  // disable crop controls
  function disableCropControls() {
    enableCropControls(false);
  }
  
  // get height for a given width (maintaing aspect ratio)
  function getHeight(width, origWidth, origHeight) {
    var height = parseInt((origHeight/origWidth) * width, 10);
    return height;
  }
  
  // get width for a given height (maintaing aspect ratio)
  function getWidth(height, origWidth, origHeight) {
    var width = parseInt((origWidth/origHeight) * height, 10);
    return width;
  }
  
  $('#json-data').click(function() {
    alert(JSON.stringify(imgData, null, 4));
  });
});

