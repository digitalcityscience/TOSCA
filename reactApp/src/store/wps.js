const baseURL = "http://localhost:5000/"; // will be moved to .env in following iteration

const parseWPSResponse = (response) => {
  return response.text().then(text => {
    const parser = new DOMParser();
    const document = parser.parseFromString(text, "text/xml");
    if (document.getElementsByTagName("ows:Exception").length) {
      throw new Error("Error: " + document.getElementsByTagName("ows:ExceptionText")[0].textContent);
    }
    return document;
  });
};

export const WPS = {
  GetCapabilities: () => {
    return fetch(baseURL + `wps?service=WPS&version=1.0.0&request=GetCapabilities`)
      .then(response => parseWPSResponse(response));
  },

  DescribeProcess: (identifier) => {
    return fetch(baseURL + `wps?service=WPS&version=1.0.0&request=DescribeProcess&identifier=${identifier}`)
      .then(response => parseWPSResponse(response));
  },

  Execute: (identifier, dataInputs, complexInputs) => {
    let inputs = dataInputs?.map(input => `
        <wps:Input>
            <ows:Identifier>${input.identifier}</ows:Identifier>
            <wps:Data>
                <wps:LiteralData>${input.data}</wps:LiteralData>
            </wps:Data>
        </wps:Input>`) || "";
    inputs += complexInputs?.map(input => `
        <wps:Input>
            <ows:Identifier>${input.identifier}</ows:Identifier>
            <wps:Data>
                <wps:ComplexData>${input.data}</wps:ComplexData>
            </wps:Data>
        </wps:Input>`) || "";

    return fetch(baseURL + `wps`, {
      method: "POST",
      body: `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<wps:Execute service="WPS" version="1.0.0" xmlns:wps="http://www.opengis.net/wps/1.0.0" xmlns:ows="http://www.opengis.net/ows/1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wps/1.0.0/wpsExecute_request.xsd">
    <ows:Identifier>${identifier}</ows:Identifier>
    <wps:DataInputs>${inputs}
    </wps:DataInputs>
</wps:Execute>
`
    }).then(response => parseWPSResponse(response));
  },

  upload: (formData) =>{
    return fetch(baseURL + "upload", {
      method: "POST",
      body: formData
    }).then(response => response.text());
  }
};
