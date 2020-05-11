      // == make_selection ==

      // • message id: make_selection.1
      // • text: No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. To add a location, use Add Location menu. Now click OK to exit.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'make_selection.1.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;
 
      // • message id: make_selection.2
      // • text: Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
      // • expectation: Finding an uploaded goejson file in data_from_browser directory. This file is created by the browser, when the user define interactively the selection area. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'make_selection.2.message':
        buttons = [
          buttonElement('Save').click(() => {
            saveDrawing();
          })
        ];
        break;

      // • message id: make_selection.3
      // • text: Process finished, selection is saved. To process exit, click OK.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'make_selection.3.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;
