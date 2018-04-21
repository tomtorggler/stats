---
title: Temperature
permalink: /temp/
---

{% assign mydata=site.data %}

<table>
    <thead>
        <th>Host</th>
        {% for i in (1..4) %}
            <th>T. {{ i }}</th>
        {% endfor %}
        <th>T. max</th>
        <th>Fan 1</th>
        <th>Fan 2</th>
    </thead>
    {% for file in mydata %}
        {% if file[0] contains 'stats'  %}
            {% assign myfiledata = file[1] | reverse %}
            {% for column in myfiledata limit:1 %}
            <tbody>
                <tr>
                    <td><a href="{{ site.baseurl }}/hist/{{ column.Host }}temp">{{ column.Host }}</a></td>
                    <td>{{ column.T_1 }}</td>
                    <td>{{ column.T_2 }}</td>
                    <td>{{ column.T_3 }}</td>
                    <td>{{ column.T_4 }}</td>    
                    <td>{{ column.T_max }}</td>
                    <td>{{ column.Fan_1 }}</td>
                    <td>{{ column.Fan_2 }}</td>
                </tr> 
            </tbody>
            {% endfor %}
        {% endif %}
    {% endfor %}
</table>

