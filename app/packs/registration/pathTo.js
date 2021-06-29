export default function pathTo(path) {
    var root = $('body').attr('data-application-root') || '';
    return(root + path);
}
