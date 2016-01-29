SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

Create procedure [dbo].[Bar_Graph_Email_Example] @recipient_email As varChar(255)
As
-- FOR TESTING:
-- Exec [Bar_Graph_Email_Example] 'you@domain.com'
Begin

-- Set up Example data in a temprary table
If OBJECT_ID('tempdb..##TEMPDATA') Is Not Null
	Drop Table ##TEMPDATA

Select 0 As CategoryID, 1001 As PersonID Into ##TEMPDATA
Insert Into ##TEMPDATA Select 0 As CategoryID, 1002 As PersonID
Insert Into ##TEMPDATA Select 0 As CategoryID, 1003 As PersonID
Insert Into ##TEMPDATA Select 2 As CategoryID, 1004 As PersonID
Insert Into ##TEMPDATA Select 2 As CategoryID, 1005 As PersonID
Insert Into ##TEMPDATA Select 2 As CategoryID, 1006 As PersonID
Insert Into ##TEMPDATA Select 3 As CategoryID, 1007 As PersonID
Insert Into ##TEMPDATA Select 3 As CategoryID, 1008 As PersonID
Insert Into ##TEMPDATA Select 4 As CategoryID, 1009 As PersonID
Insert Into ##TEMPDATA Select 4 As CategoryID, 1010 As PersonID

If OBJECT_ID('tempdb..##TEMPRGB') Is Not Null
	Drop Table ##TEMPRGB

-- Define the graph colors for each category
					  Select 0 As CategoryID, 'Category 1       ' As Category, '035' As R,'174' As G,'109' As B,'#FFF' As TextColor Into ##TEMPRGB
Insert Into ##TEMPRGB Select 1 As CategoryID, 'Category 2       ' As Category, '250' As R,'176' As G,'080' As B,'#FFF' As TextColor
Insert Into ##TEMPRGB Select 2 As CategoryID, 'Category 3       ' As Category, '028' As R,'170' As G,'206' As B,'#FFF' As TextColor
Insert Into ##TEMPRGB Select 3 As CategoryID, 'Category 4       ' As Category, '239' As R,'126' As G,'067' As B,'#FFF' As TextColor
Insert Into ##TEMPRGB Select 4 As CategoryID, 'Category 5       ' As Category, '218' As R,'139' As G,'194' As B,'#FFF' As TextColor

If OBJECT_ID('tempdb..##TEMPCOUNT') Is Not Null
	Drop Table ##TEMPCOUNT

-- Used to divide the category count to get a width in pixels of the table cell that is viewable in HTML
-- e.g. 0.20 = 5 people per pixel
-- e.g. 20 = 20 pixels per person
Declare @width As float
Set @width = 20

-- Get total of people per Category
Select	CategoryID,
		Cast(Count(PersonID) As VarChar(11)) As PersonCount,
		Cast(Sum(Case When PersonID Is Null Then 0 Else @width End) As VarChar(11)) As TableWidth
Into	##TEMPCOUNT
From	##TEMPDATA
Group By CategoryID
Order By CategoryID

-- Set upand send the email

Declare @query As varchar(max)
Set @query="Set NOCOUNT On; Select X.Category+
	'<br /><table>'
	+'<tr><td width=""'+Case When T.PersonCount Is Null Then '0' Else T.TableWidth End+'"" style=""color:'+X.TextColor+'; background-color:rgb('+X.R+','+X.G+','+X.B+');"">'
	+Case When T.PersonCount Is Null Then '0' Else T.PersonCount End+'</td></tr></table><br />'
From ##TEMPRGB As X
Left Join ##TEMPCOUNT As T On T.CategoryID=X.CategoryID
Order By X.CategoryID "

Declare @body As varchar(max)
Set	@body='<style>* {font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;}
	table{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;border-collapse:collapse;}
	table td, th {font-size:1em;padding:3px 7px 2px 7px; text-align:left;}
	table th {font-size:1.1em;text-align:left;padding-top:5px;padding-bottom:4px;}</style><small>SQL Job: ExampleEmailJob [Bar_Graph_Email_Example]</small><br /><br />'

EXEC msdb..sp_send_dbmail 
@profile_name='Your Email Profile',
@recipients=@recipient_email,
@subject='Person Counts by Category',
@body=@body,
@body_format='HTML',
@query=@query,
@query_result_header=0

-- Housekeeping
If OBJECT_ID('tempdb..##TEMPRGB') Is Not Null
	Drop Table ##TEMPRGB
	
If OBJECT_ID('tempdb..##TEMPCOUNT') Is Not Null
	Drop Table ##TEMPCOUNT

If OBJECT_ID('tempdb..##TEMPDATA') Is Not Null
	Drop Table ##TEMPDATA

End
