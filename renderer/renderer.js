// Make sure the page is ready
(function() {
    const queryString = window.location.search;
    const urlParams = getURLParam(queryString);

    // get the attribute string from the url
    const dna = urlParams.get('dna');

    console.log(dna)
 })();