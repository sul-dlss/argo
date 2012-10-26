function add_constraint()
{
	constraints=document.getElementById('constraints');
	text=document.getElementById('query_field').value;
	text=document.getElementById('relationship').value;
	text=document.getElementById('constraint').value;
	constraints.innerHTML+=text+'<br>';
}