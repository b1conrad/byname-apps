  var htmlTemplateStr = "<!DOCTYPE html>"
  +"\n<html lang='en'>"
  +"\n  <head>"
  +"\n    <meta charset='utf-8'>"
  +"\n    <title>Page Title</title>"
  +"\n  <head>"
  +"\n  <body>"
  +"\n    <!-- CONTENT GOES HERE -->"
  +"\n  </body>"
  +"\n</html>";

  var codeEditor = document.getElementById('codeEditor');
  var lineCounter = document.getElementById('lineCounter');
  
  var lineCountCache = 0;
  function line_counter() {
    var lineCount = codeEditor.value.split('\n').length;
    var outarr = new Array();
    if (lineCountCache != lineCount) {
      for (var x = 0; x < lineCount; x++) {
          outarr[x] = (x + 1) + '.';
      }
      lineCounter.value = outarr.join('\n');
    }
    lineCountCache = lineCount;
  }

  codeEditor.addEventListener('scroll', () => {
    lineCounter.scrollTop = codeEditor.scrollTop;
    lineCounter.scrollLeft = codeEditor.scrollLeft;
  });

  codeEditor.addEventListener('input', () => {
    line_counter();
  });

  codeEditor.addEventListener('keydown', (e) => {
    let { keyCode } = e;
    let { value, selectionStart, selectionEnd } = codeEditor;

    if (keyCode === 9) {  // TAB = 9
      e.preventDefault();
      codeEditor.value = value.slice(0, selectionStart) + '\t' + value.slice(selectionEnd);
      codeEditor.setSelectionRange(selectionStart+2, selectionStart+1)
    }
  });

  codeEditor.value = htmlTemplateStr;
  line_counter();
